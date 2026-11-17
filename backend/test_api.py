"""API checks use isolated test records and never contact a live database."""
import base64
import copy
import json
import os
import unittest
from unittest.mock import AsyncMock, patch

import httpx
from fastapi.testclient import TestClient
from backend import main

PROGRAM = {
    'id': 10, 'name': 'Housing test program', 'description': 'Rental assistance',
    'program_categories': [{'service_categories': {'id': 2, 'name': 'Housing', 'slug': 'housing'}}],
    'program_service_areas': [{'area_type': 'local', 'state_code': 'CA', 'city': 'Oakland'}],
}
ORGANIZATION = {'id': 1, 'name': 'Test organization', 'description': 'Test only', 'programs': [PROGRAM]}
REAL_ASYNC_CLIENT = httpx.AsyncClient

class ApiTests(unittest.TestCase):
    def setUp(self):
        self.environment = patch.dict(os.environ, {'SUPABASE_URL': '', 'SUPABASE_PUBLISHABLE_KEY': ''})
        self.environment.start()
        self.addCleanup(self.environment.stop)
        self.client = TestClient(main.app)
        self.addCleanup(self.client.close)

    def test_health_without_database(self):
        response = self.client.get('/api/health')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {'status': 'ok', 'database_configured': False})

    def test_missing_configuration_is_explicit(self):
        for path in ['/api/organizations', '/api/organizations/1', '/api/programs', '/api/categories']:
            self.assertEqual(self.client.get(path).status_code, 503)

    def test_privileged_and_malformed_keys_are_rejected(self):
        os.environ['SUPABASE_URL'] = 'https://example.supabase.co'
        payload = base64.urlsafe_b64encode(json.dumps({'role': 'service_role'}).encode()).decode().rstrip('=')
        for key in ['sb_secret_test', f'header.{payload}.signature', 'not-a-key']:
            os.environ['SUPABASE_PUBLISHABLE_KEY'] = key
            self.assertEqual(self.client.get('/api/categories').status_code, 503)

    def test_cors_and_read_only_routes(self):
        response = self.client.get('/api/health', headers={'Origin': 'http://localhost:5173'})
        self.assertEqual(response.headers['access-control-allow-origin'], 'http://localhost:5173')
        response = self.client.get('/api/health', headers={'Origin': 'https://untrusted.example'})
        self.assertNotIn('access-control-allow-origin', response.headers)
        self.assertEqual(self.client.post('/api/organizations', json={}).status_code, 405)

    def test_detail_not_found_and_invalid_ids(self):
        with patch.object(main, 'read_table', AsyncMock(return_value=[])):
            self.assertEqual(self.client.get('/api/organizations/999').status_code, 404)
        for identifier in ['0', '-1', 'abc', '9223372036854775808']:
            self.assertEqual(self.client.get(f'/api/organizations/{identifier}').status_code, 422)

    def test_directory_and_detail_relationships(self):
        with patch.object(main, 'read_table', AsyncMock(return_value=[copy.deepcopy(ORGANIZATION)])) as query:
            rows = self.client.get('/api/organizations').json()
            self.assertEqual(rows[0]['programs'][0]['id'], 10)
            self.assertEqual(query.call_args.args[1]['programs.status'], 'eq.published')
        with patch.object(main, 'read_table', AsyncMock(return_value=[copy.deepcopy(ORGANIZATION)])):
            self.assertEqual(self.client.get('/api/organizations/1').json()['name'], 'Test organization')

    def test_keyword_and_category_search(self):
        for query, expected in [('q=oakland', 1), ('q=TEST%20ORGANIZATION&category=housing', 1), ('category=health', 0), ('q=unmatched', 0)]:
            with patch.object(main, 'read_table', AsyncMock(return_value=[copy.deepcopy(ORGANIZATION)])):
                self.assertEqual(len(self.client.get(f'/api/organizations?{query}').json()), expected)
        self.assertEqual(self.client.get('/api/organizations', params={'q': 'x' * 201}).status_code, 422)

    def test_program_endpoint_embeds_organization(self):
        program = {**PROGRAM, 'organizations': {'name': 'Test organization'}}
        with patch.object(main, 'read_table', AsyncMock(return_value=[program])) as query:
            self.assertEqual(len(self.client.get('/api/programs?category=housing&q=organization').json()), 1)
            self.assertEqual(query.call_args.args[1]['status'], 'eq.published')
            self.assertIn('organizations(', query.call_args.args[1]['select'])

    def request_with_transport(self, handler, key='sb_publishable_test'):
        os.environ['SUPABASE_URL'] = 'https://example.supabase.co'
        os.environ['SUPABASE_PUBLISHABLE_KEY'] = key
        transport = httpx.MockTransport(handler)
        with patch.object(main.httpx, 'AsyncClient', side_effect=lambda **kwargs: REAL_ASYNC_CLIENT(transport=transport, **kwargs)):
            return self.client.get('/api/categories')

    def test_supabase_request_and_publishable_key_header(self):
        def upstream(request):
            self.assertEqual(str(request.url.copy_with(query=None)), 'https://example.supabase.co/rest/v1/service_categories')
            self.assertEqual(request.url.params['select'], 'id,name,slug')
            self.assertEqual(request.headers['apikey'], 'sb_publishable_test')
            self.assertNotIn('authorization', request.headers)
            return httpx.Response(200, json=[{'id': 2, 'name': 'Housing', 'slug': 'housing'}])
        self.assertEqual(self.request_with_transport(upstream).json()[0]['slug'], 'housing')

    def test_legacy_anon_key_header(self):
        payload = base64.urlsafe_b64encode(b'{"role":"anon"}').decode().rstrip('=')
        key = f'header.{payload}.signature'
        def upstream(request):
            self.assertEqual(request.headers['authorization'], f'Bearer {key}')
            return httpx.Response(200, json=[])
        self.assertEqual(self.request_with_transport(upstream, key).status_code, 200)

    def test_upstream_errors_are_sanitized(self):
        for status, body in [(401, {'message': 'private-upstream-detail'}), (200, {'unexpected': 'shape'})]:
            response = self.request_with_transport(lambda request: httpx.Response(status, json=body))
            self.assertEqual(response.status_code, 502)
            self.assertNotIn('private-upstream-detail', response.text)
        def timeout(request):
            raise httpx.ReadTimeout('private-upstream-detail')
        self.assertEqual(self.request_with_transport(timeout).status_code, 502)

if __name__ == '__main__':
    unittest.main()
