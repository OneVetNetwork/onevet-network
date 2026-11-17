import { useEffect, useState } from 'react'
import './App.css'

const API_BASE = (import.meta.env.VITE_API_BASE_URL ?? (import.meta.env.DEV ? 'http://127.0.0.1:8000' : '')).replace(/\/$/, '')

function useApi(path) {
  const [result, setResult] = useState({ data: null, error: '', loading: true })
  useEffect(() => {
    const controller = new AbortController()
    setResult({ data: null, error: '', loading: true })
    async function load() {
      try {
        const response = await fetch(`${API_BASE}${path}`, { signal: controller.signal })
        const body = await response.json()
        if (!response.ok) throw new Error(typeof body.detail === 'string' ? body.detail : 'The API could not load these records.')
        setResult({ data: body, error: '', loading: false })
      } catch (error) {
        if (error.name !== 'AbortError') setResult({ data: null, error: error instanceof TypeError ? 'Cannot reach the backend. Check that FastAPI is running and VITE_API_BASE_URL is correct.' : error.message, loading: false })
      }
    }
    load()
    return () => controller.abort()
  }, [path])
  return result
}

function Status({ result }) {
  if (result.loading) return <p role="status">Loading...</p>
  if (result.error) return <p role="alert">{result.error}</p>
  return null
}

function ExternalLink({ href, children, ...props }) {
  if (!href || !/^https?:\/\//i.test(href)) return null
  return <a href={href} target="_blank" rel="noopener noreferrer" {...props}>{children}</a>
}

function serviceArea(program) {
  return program.program_service_areas.map(area => {
    if (area.area_type === 'nationwide') return 'Nationwide (United States)'
    if (area.area_type === 'statewide') return `${area.state_code} (statewide)`
    return `${area.city}, ${area.state_code}`
  }).join('; ') || 'Contact the organization for service locations.'
}

function Contact({ record }) {
  return <>
    {record.contact_phone && <p>Phone: <a href={`tel:${record.contact_phone}`}>{record.contact_phone}</a></p>}
    {record.contact_email && <p>Email: <a href={`mailto:${record.contact_email}`}>{record.contact_email}</a></p>}
  </>
}

function Home() {
  return <>
    <h1>OneVet Network</h1>
    <p>A website to help veterans find organizations and programs that provide assistance.</p>
    <p className="home-actions">
      <button onClick={() => { window.location.href = '/profile' }}>Create a Profile</button>
      <button onClick={() => { window.location.href = '/programs' }}>Browse Programs</button>
    </p>
    <p>OneVet is intended to bring information about veteran assistance programs into one place.</p>
  </>
}

function Directory() {
  const params = new URLSearchParams(window.location.search)
  const [keyword, setKeyword] = useState(params.get('q') || '')
  const [category, setCategory] = useState(params.get('category') || '')
  const result = useApi(`/api/organizations?${params}`)
  const categories = useApi('/api/categories')
  return <>
    <h1>Organizations and Assistance Programs</h1>
    <form action="/programs" method="get">
      <label htmlFor="search">Search programs or organizations: </label>
      <input id="search" name="q" type="search" maxLength={200} value={keyword} onChange={event => setKeyword(event.target.value)} />{' '}
      <label htmlFor="category">Category: </label>
      <select id="category" name="category" value={category} onChange={event => setCategory(event.target.value)}>
        <option value="">All categories</option>
        {categories.data?.map(item => <option key={item.id} value={item.slug}>{item.name}</option>)}
      </select>{' '}
      <button type="submit">Search</button>{' '}
      <a href="/programs">Clear</a>
    </form>
    {categories.error && <p role="alert">Categories unavailable: {categories.error}</p>}
    <Status result={result} />
    {result.data && <>
      <p>{result.data.length} organization(s) found.</p>
      {result.data.length === 0 && <p>No organizations found. Clear the search, or check that the database seed has been loaded.</p>}
      {result.data.map(organization => <section key={organization.id}>
        <h2><a href={`/organizations/${organization.id}`}>{organization.name}</a></h2>
        <p>{organization.description?.split('\n\n')[0]}</p>
        <ul>{organization.programs.map(program => <li key={program.id}>
          <strong>{program.name}</strong> — {serviceArea(program)}
        </li>)}</ul>
        {organization.programs.length === 0 && <p>No published programs listed.</p>}
        <hr />
      </section>)}
    </>}
  </>
}

function Organization({ id }) {
  const result = useApi(`/api/organizations/${id}`)
  const organization = result.data
  return <>
    <p><a href="/programs">Back to Directory</a></p>
    <Status result={result} />
    {organization && <>
      <h1>{organization.name}</h1>
      <p><ExternalLink href={organization.website_url}>Official website</ExternalLink></p>
      <p>{organization.description?.split('\n\n')[0]}</p>
      <h2>About the organization</h2>
      <p>Organization type: {organization.organization_type}</p>
      {organization.description?.split('\n\n').slice(1).map((paragraph, index) => <p key={index}>{paragraph}</p>)}
      <h2>Contact information</h2>
      <Contact record={organization} />
      <h2>Programs and services offered</h2>
      {organization.programs.length === 0 && <p>No published programs listed.</p>}
      {organization.programs.map(program => <section key={program.id}>
        <h3>{program.name}</h3>
        {program.description?.split('\n\n').map((paragraph, index) => <p key={index}>{paragraph}</p>)}
        <p>Category: {program.program_categories.map(link => link.service_categories?.name).filter(Boolean).join(', ') || 'Not listed'}</p>
        <h4>General eligibility requirements</h4>
        <p>{program.eligibility_notes || 'Contact the organization to confirm eligibility.'}</p>
        {program.eligibility_criteria.length > 0 && <ul>{program.eligibility_criteria.map((criterion, index) => <li key={index}>
          {criterion.criterion_description}{' '}<ExternalLink href={criterion.source_url}>Eligibility source</ExternalLink>
        </li>)}</ul>}
        <h4>Geographic service area</h4>
        <p>{serviceArea(program)}</p>
        <Contact record={program} />
        <h4>How to receive assistance</h4>
        <p>Follow the official instructions below. The organization determines eligibility and availability.</p>
        <p><ExternalLink className="assistance-link" href={program.application_url || program.website_url}>
          {program.application_url ? 'Apply' : 'How to Get Assistance'}
        </ExternalLink> (opens in a new tab)</p>
        <p><ExternalLink href={program.website_url}>Official program information and source</ExternalLink></p>
        {program.last_verified_at && <p>Information verified: {program.last_verified_at.slice(0, 10)}</p>}
        <hr />
      </section>)}
      <p><a href="/programs">Back to Directory</a></p>
    </>}
  </>
}

function App() {
  const path = window.location.pathname.replace(/\/$/, '') || '/'
  const organizationMatch = path.match(/^\/organizations\/([1-9]\d*)$/)
  let page
  if (path === '/') page = <Home />
  else if (path === '/programs') page = <Directory />
  else if (organizationMatch) page = <Organization id={organizationMatch[1]} />
  else if (path === '/profile') page = <>
    <h1>Veteran Profile and Needs Assessment</h1>
    <p>This feature is currently under development. In the future, users will be able to complete an assessment to receive personalized program recommendations.</p>
    <a href="/">Back to Home</a>
  </>
  else if (path === '/about') page = <>
    <h1>About OneVet Network</h1>
    <p>This section is currently under development.</p>
    <a href="/">Home</a>
  </>
  else page = <><h1>Page not found</h1><a href="/">Back to Home</a></>
  return <>
    <nav aria-label="Main navigation">
      <a href="/">Home</a> | <a href="/programs">Browse Programs</a> | <a href="/profile">My Profile</a> | <a href="/about">About Us</a>
    </nav>
    <main>{page}</main>
  </>
}

export default App
