-- OneVet prototype: manually verified official sources, November 16, 2026.
-- Run manually in Supabase SQL Editor against the EXISTING schema.
-- This file updates only the five named organizations and their named programs.
-- It never changes policies, creates public tables, or grants write access.
BEGIN;
-- Serialize concurrent runs of this seed, including eligibility rows without a unique key.
SELECT pg_advisory_xact_lock(370, 5);

CREATE TEMP TABLE onevet_seed (
  organization_name text, organization_type text, organization_description text,
  organization_website text, organization_email text, organization_phone text,
  program_name text, program_description text, eligibility_notes text,
  program_website text, application_url text, program_phone text,
  category_slug text, category_name text, area_type text, state_code text, city text,
  criterion_description text, eligibility_source text
) ON COMMIT DROP;

INSERT INTO onevet_seed VALUES
(
  'U.S. Department of Veterans Affairs (VA)', 'government',
  E'Federal agency providing benefits and services for veterans.\n\nVA health benefits include care through VA medical centers and clinics. Enrollment begins with a health benefits application.',
  'https://www.va.gov/', NULL, '877-222-8387',
  'VA Health Care',
  E'Health care benefits for eligible veterans through the VA system.\n\nHow to receive assistance: complete VA Form 10-10EZ online, by phone, by mail, or at a VA medical center. The official instructions explain supporting documents.',
  'Eligibility depends on military service and discharge history, with minimum service rules and exceptions. VA makes the enrollment decision.',
  'https://www.va.gov/health-care/how-to-apply/',
  'https://www.va.gov/forms/10-10ez/apply-va-healthcare/', '877-222-8387',
  'health-care', 'Health Care', 'nationwide', NULL, NULL,
  'Generally requires active military service without a dishonorable discharge. Minimum active-duty requirements may apply; exceptions and National Guard/Reserve rules are described by VA.',
  'https://www.va.gov/health-care/eligibility/'
),
(
  'California Department of Veterans Affairs (CalVet)', 'government',
  E'California state department helping veterans and their families access benefits.\n\nCalVet connects California veterans with state and federal benefits earned through military service. Home loans are one of its services.',
  'https://www.calvet.ca.gov/', 'contactuscommunications@calvet.ca.gov', '800-952-5626',
  'CalVet Home Loans',
  E'Home financing for veterans purchasing an owner-occupied home in California.\n\nHow to receive assistance: start the online pre-approval application linked by CA.gov or call the home loan team. A CalVet representative guides applicants through the lending process.',
  'CA.gov lists at least 90 days of active service excluding training, discharge under honorable conditions, and no current CalVet Home Loan. The property must be in California; lending review also applies.',
  'https://www.ca.gov/departments/163/services/64/',
  'https://calvet.zipforhome.com/', '866-653-2510',
  'housing', 'Housing', 'statewide', 'CA', NULL,
  'The loan is for an owner-occupied California home. Review the official service page and contact CalVet to confirm service and loan qualifications.',
  'https://www.ca.gov/departments/163/services/64/'
),
(
  'Wounded Warrior Project', 'nonprofit',
  E'Nonprofit offering support programs for veterans, service members, and their families.\n\nFounded in 2003, Wounded Warrior Project began by providing care items to wounded service members and expanded into support programs and advocacy.',
  'https://www.woundedwarriorproject.org/', NULL, '888-997-2586',
  'Veteran Registration and Support Services',
  E'Registration connects eligible participants with no-cost programs for connection, wellness, benefits, and career support.\n\nHow to receive assistance: complete the official warrior registration form or call the registration team. Family support members have a separate registration option on the program information page.',
  'The registration page lists veterans who served on or after September 11, 2001, active-duty and transitioning service members, eligible Guard/Reserve members, and family or caregivers. WWP confirms eligibility and documentation.',
  'https://www.woundedwarriorproject.org/programs/wwp-registration',
  'https://www.woundedwarriorproject.org/programs/wwp-registration/alumni', '888-997-2586',
  'veteran-support', 'Veteran Support', 'nationwide', NULL, NULL,
  'A visible or combat-related injury is not required according to the current registration page. Contact WWP if unsure about documentation or eligibility.',
  'https://www.woundedwarriorproject.org/programs/wwp-registration'
),
(
  'Operation Homefront', 'nonprofit',
  E'National nonprofit assisting military and veteran families.\n\nOperation Homefront has served military families since 2002 through financial relief, housing, and family support programs.',
  'https://operationhomefront.org/', NULL, '877-264-3968',
  'Critical Financial Assistance',
  E'Short-term help for eligible military families with critical expenses such as housing, utilities, and food.\n\nHow to receive assistance: review eligibility, then use My Operation Homefront during the application window. The process page currently states the 1st through the 10th of each month, closing at 11:59 PM CST on the 10th. Check the current official instructions before applying.',
  'Eligibility differs for wounded/ill/injured, deployed, and general active-duty applicants. Documentation and available expense types differ. Review the full official criteria.',
  'https://operationhomefront.org/cfa-process/',
  NULL, '877-264-3968',
  'financial-assistance', 'Financial Assistance', 'nationwide', NULL, NULL,
  'The wounded/ill/injured route includes post-9/11 service and a line-of-duty condition; discharged applicants need Honorable or General (Under Honorable Conditions) discharge and separation within 10 years. Separate deployment and active-duty routes have rank and dependent requirements.',
  'https://operationhomefront.org/cfa-eligibility/'
),
(
  'Swords to Plowshares', 'nonprofit',
  E'Community nonprofit supporting veterans in the San Francisco Bay Area.\n\nFounded by Vietnam-era veterans in 1974, Swords to Plowshares provides housing and other services to help veterans achieve stability.\n\nService centers: 1060 Howard St, San Francisco, CA 94103; 330 Franklin St, Suite 100, Oakland, CA 94607. Oakland phone: 510-844-7500.',
  'https://www.swords-to-plowshares.org/', 'supportvets@stp-sf.org', '415-252-4788',
  'Bay Area Housing Assistance',
  E'Help finding and keeping housing, including temporary housing connections, supportive housing, rent support, and eviction prevention. Services support veterans in the San Francisco Bay Area.\n\nHow to receive assistance: call or visit a veterans center, or use the Connect to Care form at https://www.swords-to-plowshares.org/get-care. Staff assess needs and determine which housing services fit. This is contact and intake guidance, not a direct housing application.',
  'Services begin with proof of military service; staff can help obtain it. Bay Area veterans may contact the organization regardless of discharge status or VA eligibility. Individual housing programs have additional requirements.',
  'https://www.swords-to-plowshares.org/services/housing',
  NULL, '415-252-4788',
  'housing', 'Housing', 'local', 'CA', 'San Francisco',
  'Contact the organization for a housing assessment. General access to services does not guarantee eligibility for a particular housing program or an available placement.',
  'https://www.swords-to-plowshares.org/get-care'
);

INSERT INTO public.organizations (name, organization_type, description, website_url, contact_email, contact_phone)
SELECT organization_name, organization_type, organization_description, organization_website, organization_email, organization_phone
FROM onevet_seed
ON CONFLICT (name) DO UPDATE SET
  organization_type = EXCLUDED.organization_type,
  description = EXCLUDED.description,
  website_url = EXCLUDED.website_url,
  contact_email = EXCLUDED.contact_email,
  contact_phone = EXCLUDED.contact_phone,
  updated_at = now();

INSERT INTO public.service_categories (slug, name)
SELECT DISTINCT category_slug, category_name FROM onevet_seed
ON CONFLICT DO NOTHING;

INSERT INTO public.programs (
  organization_id, name, description, eligibility_notes, website_url, application_url,
  contact_phone, delivery_mode, status, last_verified_at
)
SELECT o.id, s.program_name, s.program_description, s.eligibility_notes,
  s.program_website, s.application_url, s.program_phone, 'hybrid', 'published',
  '2026-11-16T00:00:00Z'::timestamptz
FROM onevet_seed s JOIN public.organizations o ON o.name = s.organization_name
ON CONFLICT (organization_id, name) DO UPDATE SET
  description = EXCLUDED.description,
  eligibility_notes = EXCLUDED.eligibility_notes,
  website_url = EXCLUDED.website_url,
  application_url = EXCLUDED.application_url,
  contact_phone = EXCLUDED.contact_phone,
  delivery_mode = EXCLUDED.delivery_mode,
  status = EXCLUDED.status,
  last_verified_at = EXCLUDED.last_verified_at,
  updated_at = now();

CREATE TEMP TABLE onevet_seed_programs ON COMMIT DROP AS
SELECT p.id AS program_id, s.*
FROM onevet_seed s
JOIN public.organizations o ON o.name = s.organization_name
JOIN public.programs p ON p.organization_id = o.id AND p.name = s.program_name;

INSERT INTO public.program_categories (program_id, category_id)
SELECT s.program_id, c.id
FROM onevet_seed_programs s
JOIN LATERAL (
  SELECT id FROM public.service_categories
  WHERE slug = s.category_slug OR name = s.category_name
  ORDER BY (slug = s.category_slug) DESC LIMIT 1
) c ON true
ON CONFLICT DO NOTHING;

INSERT INTO public.program_service_areas (program_id, area_type, state_code, city)
SELECT program_id, area_type, state_code, city FROM onevet_seed_programs
ON CONFLICT DO NOTHING;

INSERT INTO public.program_service_areas (program_id, area_type, state_code, city)
SELECT program_id, 'local', 'CA', 'Oakland' FROM onevet_seed_programs
WHERE organization_name = 'Swords to Plowshares'
ON CONFLICT DO NOTHING;

UPDATE public.eligibility_criteria e
SET criterion_description = s.criterion_description, source_url = s.eligibility_source
FROM onevet_seed_programs s
WHERE e.program_id = s.program_id AND e.criterion_name = 'Prototype eligibility summary';

INSERT INTO public.eligibility_criteria (program_id, criterion_name, criterion_description, source_url)
SELECT s.program_id, 'Prototype eligibility summary', s.criterion_description, s.eligibility_source
FROM onevet_seed_programs s
WHERE NOT EXISTS (
  SELECT 1 FROM public.eligibility_criteria e
  WHERE e.program_id = s.program_id AND e.criterion_name = 'Prototype eligibility summary'
);

-- Expect five rows below. Existing unrelated records are preserved.
SELECT o.name AS organization, p.name AS program, p.status
FROM onevet_seed_programs s
JOIN public.programs p ON p.id = s.program_id
JOIN public.organizations o ON o.id = p.organization_id
ORDER BY o.name;
COMMIT;
