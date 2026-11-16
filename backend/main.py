"""Read-only API for the OneVet student prototype."""
import base64
import json
import os
from pathlib import Path
from typing import Annotated

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Path as ApiPath, Query
from fastapi.middleware.cors import CORSMiddleware

load_dotenv(Path(__file__).with_name('.env'))
app = FastAPI(title='OneVet Network API', version='0.1.0')
app.add_middleware(CORSMiddleware, allow_origins=['http://localhost:5173', 'http://127.0.0.1:5173'], allow_methods=['GET'], allow_headers=['Content-Type'])

ORGANIZATION_FIELDS = 'id,name,organization_type,description,website_url,contact_email,contact_phone'
PROGRAM_FIELDS = (
    'id,organization_id,name,description,eligibility_notes,website_url,application_url,'
    'contact_email,contact_phone,delivery_mode,last_verified_at,'
    'program_categories(service_categories(id,name,slug)),'
    'program_service_areas(area_type,state_code,city),'
    'eligibility_criteria(criterion_name,criterion_description,source_url)'
)

def public_key(key):
    """Accept only keys that use the anonymous database role."""
    if key.startswith('sb_publishable_'):
        return True
    try:
        payload = key.split('.')[1]
        claims = json.loads(base64.urlsafe_b64decode(payload + '=' * (-len(payload) % 4)))
        return isinstance(claims, dict) and claims.get('role') == 'anon'
    except (ValueError, IndexError, UnicodeDecodeError):
        return False

async def read_table(table, params):
    url = os.getenv('SUPABASE_URL', '').rstrip('/')
    key = os.getenv('SUPABASE_PUBLISHABLE_KEY', '').strip()
    if not url or not key:
        raise HTTPException(503, 'Database is not configured. Set SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY in backend/.env.')
    if not public_key(key):
        raise HTTPException(503, 'Configure a Supabase publishable key or legacy anon key. Privileged keys are not accepted.')
    if not url.startswith('https://'):
        raise HTTPException(503, 'SUPABASE_URL must be the HTTPS project URL.')
    headers = {'apikey': key}
    if not key.startswith('sb_publishable_'):
        headers['Authorization'] = f'Bearer {key}'
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            response = await client.get(f'{url}/rest/v1/{table}', params=params, headers=headers)
        response.raise_for_status()
        rows = response.json()
        if not isinstance(rows, list):
            raise ValueError('Expected database rows')
        return rows
    except (httpx.HTTPError, ValueError):
        # Avoid returning upstream errors that can include internal database details.
        raise HTTPException(502, 'Could not read Supabase. Check the project URL, public key, Data API access, and read policies.') from None

def matches(program, keyword, category):
    categories = [link['service_categories'] for link in program['program_categories'] if link.get('service_categories')]
    organization = program.get('organizations') or {}
    text = ' '.join(str(value or '') for value in [
        program.get('name'), program.get('description'), program.get('eligibility_notes'),
        organization.get('name'), organization.get('description'),
        *[item['name'] for item in categories],
        *[f"{area.get('city') or ''} {area.get('state_code') or ''} {area['area_type']}" for area in program['program_service_areas']],
    ]).casefold()
    return (not keyword or keyword.strip().casefold() in text) and (not category or any(item['slug'] == category for item in categories))

@app.get('/api/health')
async def health():
    return {'status': 'ok', 'database_configured': bool(os.getenv('SUPABASE_URL') and os.getenv('SUPABASE_PUBLISHABLE_KEY'))}

@app.get('/api/organizations')
async def organizations(q: Annotated[str, Query(max_length=200)] = '', category: Annotated[str, Query(max_length=100)] = ''):
    rows = await read_table('organizations', {'select': f'{ORGANIZATION_FIELDS},programs({PROGRAM_FIELDS})', 'order': 'name.asc', 'programs.status': 'eq.published'})
    if q.strip() or category:
        for row in rows:
            row['programs'] = [p for p in row['programs'] if matches({**p, 'organizations': row}, q, category)]
        rows = [row for row in rows if row['programs']]
    return rows

@app.get('/api/organizations/{organization_id}')
async def organization_detail(organization_id: Annotated[int, ApiPath(gt=0, le=9223372036854775807)]):
    rows = await read_table('organizations', {'select': f'{ORGANIZATION_FIELDS},programs({PROGRAM_FIELDS})', 'id': f'eq.{organization_id}', 'programs.status': 'eq.published'})
    if not rows:
        raise HTTPException(404, 'Organization not found.')
    return rows[0]

@app.get('/api/programs')
async def programs(q: Annotated[str, Query(max_length=200)] = '', category: Annotated[str, Query(max_length=100)] = ''):
    rows = await read_table('programs', {'select': f'{PROGRAM_FIELDS},organizations({ORGANIZATION_FIELDS})', 'status': 'eq.published', 'order': 'name.asc'})
    return [row for row in rows if matches(row, q, category)]

@app.get('/api/categories')
async def categories():
    return await read_table('service_categories', {'select': 'id,name,slug', 'order': 'name.asc'})
