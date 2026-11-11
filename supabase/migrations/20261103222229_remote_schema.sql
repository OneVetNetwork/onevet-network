CREATE TABLE "public"."assessment_needs" (
  "assessment_id" bigint NOT NULL,
  "category_id"   bigint NOT NULL,
  CONSTRAINT "assessment_needs_pkey" PRIMARY KEY (assessment_id, category_id)
);

ALTER TABLE "public"."assessment_needs"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."assessment_needs" FROM "anon", "authenticated";

CREATE TABLE "public"."assessment_shares" (
  "assessment_id"     bigint                   NOT NULL,
  "recipient_user_id" uuid                     NOT NULL,
  "shared_at"         timestamp with time zone NOT NULL DEFAULT now(),
  "revoked_at"        timestamp with time zone,
  CONSTRAINT "assessment_shares_pkey" PRIMARY KEY (assessment_id, recipient_user_id)
);

ALTER TABLE "public"."assessment_shares"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."assessment_shares" FROM "anon", "authenticated";

CREATE TABLE "public"."eligibility_criteria" (
  "id"                    bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  "program_id"            bigint NOT NULL,
  "criterion_name"        text   NOT NULL,
  "criterion_description" text   NOT NULL,
  "source_url"            text,
  CONSTRAINT "eligibility_criteria_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."eligibility_criteria"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."needs_assessments" (
  "id"         bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "user_id"    uuid                     NOT NULL,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "needs_assessments_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."needs_assessments"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."needs_assessments" FROM "anon", "authenticated";

CREATE TABLE "public"."organizations" (
  "id"                bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "name"              text                     NOT NULL,
  "organization_type" text                     NOT NULL,
  "description"       text,
  "website_url"       text,
  "contact_email"     text,
  "contact_phone"     text,
  "created_at"        timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"        timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "organizations_name_key" UNIQUE (name),
  CONSTRAINT "organizations_organization_type_check" CHECK ((organization_type = ANY (ARRAY['vso'::text, 'nonprofit'::text, 'government'::text, 'other'::text]))),
  CONSTRAINT "organizations_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."organizations"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."program_categories" (
  "program_id"  bigint NOT NULL,
  "category_id" bigint NOT NULL,
  CONSTRAINT "program_categories_pkey" PRIMARY KEY (program_id, category_id)
);

ALTER TABLE "public"."program_categories"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."program_service_areas" (
  "id"         bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  "program_id" bigint NOT NULL,
  "area_type"  text   NOT NULL,
  "state_code" text,
  "city"       text,
  CONSTRAINT "program_service_areas_area_type_check" CHECK ((area_type = ANY (ARRAY['nationwide'::text, 'statewide'::text, 'local'::text]))),
  CONSTRAINT "program_service_areas_check"
    CHECK ((((area_type = 'nationwide'::text) AND (state_code IS NULL) AND (city IS NULL)) OR ((area_type = 'statewide'::text) AND (state_code IS
    NOT NULL) AND (city IS NULL)) OR ((area_type = 'local'::text) AND (state_code IS NOT NULL) AND (NULLIF(btrim(city), ''::text) IS NOT NULL)))),
  CONSTRAINT "program_service_areas_pkey" PRIMARY KEY (id),
  CONSTRAINT "program_service_areas_state_code_check" CHECK ((state_code ~ '^[A-Z]{2}$'::text))
);

ALTER TABLE "public"."program_service_areas"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."programs" (
  "id"                bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "organization_id"   bigint                   NOT NULL,
  "name"              text                     NOT NULL,
  "program_type"      text                     NOT NULL DEFAULT 'service'::text,
  "description"       text,
  "eligibility_notes" text,
  "website_url"       text,
  "application_url"   text,
  "contact_email"     text,
  "contact_phone"     text,
  "delivery_mode"     text                     NOT NULL DEFAULT 'in_person'::text,
  "status"            text                     NOT NULL DEFAULT 'draft'::text,
  "last_verified_at"  timestamp with time zone,
  "created_at"        timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"        timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "programs_delivery_mode_check" CHECK ((delivery_mode = ANY (ARRAY['in_person'::text, 'online'::text, 'hybrid'::text]))),
  CONSTRAINT "programs_organization_id_name_key" UNIQUE (organization_id, name),
  CONSTRAINT "programs_pkey" PRIMARY KEY (id),
  CONSTRAINT "programs_status_check" CHECK ((status = ANY (ARRAY['draft'::text, 'published'::text, 'archived'::text])))
);

ALTER TABLE "public"."programs"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."recommendations" (
  "id"               bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "assessment_id"    bigint                   NOT NULL,
  "program_id"       bigint                   NOT NULL,
  "reason_for_match" text                     NOT NULL,
  "match_score"      smallint,
  "created_at"       timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "recommendations_assessment_id_program_id_key" UNIQUE (assessment_id, program_id),
  CONSTRAINT "recommendations_match_score_check" CHECK (((match_score >= 0) AND (match_score <= 100))),
  CONSTRAINT "recommendations_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."recommendations"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."recommendations" FROM "anon", "authenticated";

CREATE TABLE "public"."referrals" (
  "id"         bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "user_id"    uuid                     NOT NULL,
  "program_id" bigint                   NOT NULL,
  "status"     text                     NOT NULL DEFAULT 'planned'::text,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "referrals_pkey" PRIMARY KEY (id),
  CONSTRAINT "referrals_status_check" CHECK ((status = ANY (ARRAY['planned'::text, 'contacted'::text, 'applied'::text, 'completed'::text, 'cancelled'::text])))
);

ALTER TABLE "public"."referrals"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."referrals" FROM "anon", "authenticated";

CREATE TABLE "public"."saved_programs" (
  "user_id"    uuid                     NOT NULL,
  "program_id" bigint                   NOT NULL,
  "saved_at"   timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "saved_programs_pkey" PRIMARY KEY (user_id, program_id)
);

ALTER TABLE "public"."saved_programs"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."saved_programs" FROM "anon", "authenticated";

CREATE TABLE "public"."service_categories" (
  "id"   bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  "slug" text   NOT NULL,
  "name" text   NOT NULL,
  CONSTRAINT "service_categories_name_key" UNIQUE (name),
  CONSTRAINT "service_categories_pkey" PRIMARY KEY (id),
  CONSTRAINT "service_categories_slug_key" UNIQUE (slug)
);

ALTER TABLE "public"."service_categories"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."user_profiles" (
  "id"                   uuid                     NOT NULL,
  "first_name"           text,
  "last_name"            text,
  "email"                text                     NOT NULL,
  "account_role"         text                     NOT NULL DEFAULT 'veteran'::text,
  "service_branch"       text,
  "preferred_state_code" text,
  "local_only"           boolean                  NOT NULL DEFAULT false,
  "nonprofit_only"       boolean                  NOT NULL DEFAULT false,
  "created_at"           timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"           timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "user_profiles_account_role_check" CHECK ((account_role = ANY (ARRAY['veteran'::text, 'case_manager'::text, 'caregiver'::text, 'organization'::text, 'admin'::text]))),
  CONSTRAINT "user_profiles_email_key" UNIQUE (email),
  CONSTRAINT "user_profiles_pkey" PRIMARY KEY (id),
  CONSTRAINT "user_profiles_preferred_state_code_check" CHECK ((preferred_state_code ~ '^[A-Z]{2}$'::text)),
  CONSTRAINT "user_profiles_service_branch_check"
    CHECK
    ((service_branch = ANY (ARRAY['army'::text, 'navy'::text, 'air_force'::text, 'marine_corps'::text, 'coast_guard'::text, 'space_force'::text, 'national_guard'::text,
    'reserve'::text, 'other'::text, 'prefer_not_to_say'::text])))
);

ALTER TABLE "public"."user_profiles"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."user_profiles" FROM "anon", "authenticated";

ALTER TABLE "public"."assessment_needs"
  ADD CONSTRAINT "assessment_needs_assessment_id_fkey" FOREIGN KEY (assessment_id) REFERENCES public.needs_assessments(id) ON DELETE CASCADE;

ALTER TABLE "public"."assessment_shares"
  ADD CONSTRAINT "assessment_shares_assessment_id_fkey" FOREIGN KEY (assessment_id) REFERENCES public.needs_assessments(id) ON DELETE CASCADE;

ALTER TABLE "public"."programs"
  ADD CONSTRAINT "programs_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE RESTRICT;

ALTER TABLE "public"."eligibility_criteria"
  ADD CONSTRAINT "eligibility_criteria_program_id_fkey" FOREIGN KEY (program_id) REFERENCES public.programs(id) ON DELETE CASCADE;

ALTER TABLE "public"."program_categories"
  ADD CONSTRAINT "program_categories_program_id_fkey" FOREIGN KEY (program_id) REFERENCES public.programs(id) ON DELETE CASCADE;

ALTER TABLE "public"."program_service_areas"
  ADD CONSTRAINT "program_service_areas_program_id_fkey" FOREIGN KEY (program_id) REFERENCES public.programs(id) ON DELETE CASCADE;

ALTER TABLE "public"."recommendations"
  ADD CONSTRAINT "recommendations_assessment_id_fkey" FOREIGN KEY (assessment_id) REFERENCES public.needs_assessments(id) ON DELETE CASCADE;

ALTER TABLE "public"."recommendations"
  ADD CONSTRAINT "recommendations_program_id_fkey" FOREIGN KEY (program_id) REFERENCES public.programs(id) ON DELETE RESTRICT;

ALTER TABLE "public"."referrals"
  ADD CONSTRAINT "referrals_program_id_fkey" FOREIGN KEY (program_id) REFERENCES public.programs(id) ON DELETE RESTRICT;

ALTER TABLE "public"."saved_programs"
  ADD CONSTRAINT "saved_programs_program_id_fkey" FOREIGN KEY (program_id) REFERENCES public.programs(id) ON DELETE CASCADE;

ALTER TABLE "public"."assessment_needs"
  ADD CONSTRAINT "assessment_needs_category_id_fkey" FOREIGN KEY (category_id) REFERENCES public.service_categories(id) ON DELETE RESTRICT;

ALTER TABLE "public"."program_categories"
  ADD CONSTRAINT "program_categories_category_id_fkey" FOREIGN KEY (category_id) REFERENCES public.service_categories(id) ON DELETE RESTRICT;

ALTER TABLE "public"."user_profiles"
  ADD CONSTRAINT "user_profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE "public"."assessment_shares"
  ADD CONSTRAINT "assessment_shares_recipient_user_id_fkey" FOREIGN KEY (recipient_user_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE;

ALTER TABLE "public"."needs_assessments"
  ADD CONSTRAINT "needs_assessments_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE;

ALTER TABLE "public"."referrals"
  ADD CONSTRAINT "referrals_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE;

ALTER TABLE "public"."saved_programs"
  ADD CONSTRAINT "saved_programs_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE;

CREATE INDEX idx_assessment_needs_category ON public.assessment_needs USING btree (category_id);

CREATE INDEX idx_assessment_shares_recipient ON public.assessment_shares USING btree (recipient_user_id);

CREATE INDEX idx_assessments_user ON public.needs_assessments USING btree (user_id);

CREATE INDEX idx_eligibility_program ON public.eligibility_criteria USING btree (program_id);

CREATE INDEX idx_program_categories_category ON public.program_categories USING btree (category_id);

CREATE INDEX idx_programs_org ON public.programs USING btree (organization_id);

CREATE INDEX idx_programs_status ON public.programs USING btree (status);

CREATE INDEX idx_recommendations_program ON public.recommendations USING btree (program_id);

CREATE INDEX idx_referrals_user ON public.referrals USING btree (user_id);

CREATE INDEX idx_saved_programs_program ON public.saved_programs USING btree (program_id);

CREATE INDEX idx_service_areas_state ON public.program_service_areas USING btree (state_code, area_type);

CREATE UNIQUE INDEX unique_program_service_area ON public.program_service_areas USING btree (program_id, area_type, COALESCE(state_code, ''::text), COALESCE(lower(city), ''::text));

CREATE POLICY "Public can read published eligibility criteria" ON "public"."eligibility_criteria"
  FOR SELECT
  TO "anon", "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM public.programs p
  WHERE ((p.id = eligibility_criteria.program_id) AND (p.status = 'published'::text)))));

CREATE POLICY "Public can read organizations" ON "public"."organizations"
  FOR SELECT
  TO "anon", "authenticated"
  USING (true);

CREATE POLICY "Public can read published program categories" ON "public"."program_categories"
  FOR SELECT
  TO "anon", "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM public.programs p
  WHERE ((p.id = program_categories.program_id) AND (p.status = 'published'::text)))));

CREATE POLICY "Public can read published service areas" ON "public"."program_service_areas"
  FOR SELECT
  TO "anon", "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM public.programs p
  WHERE ((p.id = program_service_areas.program_id) AND (p.status = 'published'::text)))));

CREATE POLICY "Public can read published programs" ON "public"."programs"
  FOR SELECT
  TO "anon", "authenticated"
  USING ((status = 'published'::text));

CREATE POLICY "Public can read service categories" ON "public"."service_categories"
  FOR SELECT
  TO "anon", "authenticated"
  USING (true);

REVOKE ALL ON SEQUENCE "public"."eligibility_criteria_id_seq" FROM "anon";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."eligibility_criteria_id_seq" TO "anon";

REVOKE ALL ON SEQUENCE "public"."eligibility_criteria_id_seq" FROM "authenticated";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."eligibility_criteria_id_seq" TO "authenticated";

REVOKE ALL ON SEQUENCE "public"."eligibility_criteria_id_seq" FROM "postgres";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."eligibility_criteria_id_seq" TO "postgres";

REVOKE ALL ON SEQUENCE "public"."eligibility_criteria_id_seq" FROM "service_role";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."eligibility_criteria_id_seq" TO "service_role";

REVOKE ALL ON SEQUENCE "public"."needs_assessments_id_seq" FROM "anon";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."needs_assessments_id_seq" TO "anon";

REVOKE ALL ON SEQUENCE "public"."needs_assessments_id_seq" FROM "authenticated";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."needs_assessments_id_seq" TO "authenticated";

REVOKE ALL ON SEQUENCE "public"."needs_assessments_id_seq" FROM "postgres";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."needs_assessments_id_seq" TO "postgres";

REVOKE ALL ON SEQUENCE "public"."needs_assessments_id_seq" FROM "service_role";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."needs_assessments_id_seq" TO "service_role";

REVOKE ALL ON SEQUENCE "public"."organizations_id_seq" FROM "anon";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."organizations_id_seq" TO "anon";

REVOKE ALL ON SEQUENCE "public"."organizations_id_seq" FROM "authenticated";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."organizations_id_seq" TO "authenticated";

REVOKE ALL ON SEQUENCE "public"."organizations_id_seq" FROM "postgres";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."organizations_id_seq" TO "postgres";

REVOKE ALL ON SEQUENCE "public"."organizations_id_seq" FROM "service_role";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."organizations_id_seq" TO "service_role";

REVOKE ALL ON SEQUENCE "public"."program_service_areas_id_seq" FROM "anon";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."program_service_areas_id_seq" TO "anon";

REVOKE ALL ON SEQUENCE "public"."program_service_areas_id_seq" FROM "authenticated";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."program_service_areas_id_seq" TO "authenticated";

REVOKE ALL ON SEQUENCE "public"."program_service_areas_id_seq" FROM "postgres";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."program_service_areas_id_seq" TO "postgres";

REVOKE ALL ON SEQUENCE "public"."program_service_areas_id_seq" FROM "service_role";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."program_service_areas_id_seq" TO "service_role";

REVOKE ALL ON SEQUENCE "public"."programs_id_seq" FROM "anon";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."programs_id_seq" TO "anon";

REVOKE ALL ON SEQUENCE "public"."programs_id_seq" FROM "authenticated";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."programs_id_seq" TO "authenticated";

REVOKE ALL ON SEQUENCE "public"."programs_id_seq" FROM "postgres";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."programs_id_seq" TO "postgres";

REVOKE ALL ON SEQUENCE "public"."programs_id_seq" FROM "service_role";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."programs_id_seq" TO "service_role";

REVOKE ALL ON SEQUENCE "public"."recommendations_id_seq" FROM "anon";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."recommendations_id_seq" TO "anon";

REVOKE ALL ON SEQUENCE "public"."recommendations_id_seq" FROM "authenticated";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."recommendations_id_seq" TO "authenticated";

REVOKE ALL ON SEQUENCE "public"."recommendations_id_seq" FROM "postgres";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."recommendations_id_seq" TO "postgres";

REVOKE ALL ON SEQUENCE "public"."recommendations_id_seq" FROM "service_role";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."recommendations_id_seq" TO "service_role";

REVOKE ALL ON SEQUENCE "public"."referrals_id_seq" FROM "anon";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."referrals_id_seq" TO "anon";

REVOKE ALL ON SEQUENCE "public"."referrals_id_seq" FROM "authenticated";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."referrals_id_seq" TO "authenticated";

REVOKE ALL ON SEQUENCE "public"."referrals_id_seq" FROM "postgres";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."referrals_id_seq" TO "postgres";

REVOKE ALL ON SEQUENCE "public"."referrals_id_seq" FROM "service_role";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."referrals_id_seq" TO "service_role";

REVOKE ALL ON SEQUENCE "public"."service_categories_id_seq" FROM "anon";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."service_categories_id_seq" TO "anon";

REVOKE ALL ON SEQUENCE "public"."service_categories_id_seq" FROM "authenticated";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."service_categories_id_seq" TO "authenticated";

REVOKE ALL ON SEQUENCE "public"."service_categories_id_seq" FROM "postgres";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."service_categories_id_seq" TO "postgres";

REVOKE ALL ON SEQUENCE "public"."service_categories_id_seq" FROM "service_role";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."service_categories_id_seq" TO "service_role";

REVOKE ALL ON TABLE "public"."assessment_needs" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."assessment_needs" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."assessment_needs" TO "service_role";

REVOKE ALL ON TABLE "public"."assessment_shares" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."assessment_shares" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."assessment_shares" TO "service_role";

REVOKE ALL ON TABLE "public"."eligibility_criteria" FROM "anon";

GRANT SELECT ON TABLE "public"."eligibility_criteria" TO "anon";

REVOKE ALL ON TABLE "public"."eligibility_criteria" FROM "authenticated";

GRANT SELECT ON TABLE "public"."eligibility_criteria" TO "authenticated";

REVOKE ALL ON TABLE "public"."eligibility_criteria" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."eligibility_criteria" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."eligibility_criteria" TO "service_role";

REVOKE ALL ON TABLE "public"."needs_assessments" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."needs_assessments" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."needs_assessments" TO "service_role";

REVOKE ALL ON TABLE "public"."organizations" FROM "anon";

GRANT SELECT ON TABLE "public"."organizations" TO "anon";

REVOKE ALL ON TABLE "public"."organizations" FROM "authenticated";

GRANT SELECT ON TABLE "public"."organizations" TO "authenticated";

REVOKE ALL ON TABLE "public"."organizations" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."organizations" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."organizations" TO "service_role";

REVOKE ALL ON TABLE "public"."program_categories" FROM "anon";

GRANT SELECT ON TABLE "public"."program_categories" TO "anon";

REVOKE ALL ON TABLE "public"."program_categories" FROM "authenticated";

GRANT SELECT ON TABLE "public"."program_categories" TO "authenticated";

REVOKE ALL ON TABLE "public"."program_categories" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."program_categories" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."program_categories" TO "service_role";

REVOKE ALL ON TABLE "public"."program_service_areas" FROM "anon";

GRANT SELECT ON TABLE "public"."program_service_areas" TO "anon";

REVOKE ALL ON TABLE "public"."program_service_areas" FROM "authenticated";

GRANT SELECT ON TABLE "public"."program_service_areas" TO "authenticated";

REVOKE ALL ON TABLE "public"."program_service_areas" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."program_service_areas" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."program_service_areas" TO "service_role";

REVOKE ALL ON TABLE "public"."programs" FROM "anon";

GRANT SELECT ON TABLE "public"."programs" TO "anon";

REVOKE ALL ON TABLE "public"."programs" FROM "authenticated";

GRANT SELECT ON TABLE "public"."programs" TO "authenticated";

REVOKE ALL ON TABLE "public"."programs" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."programs" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."programs" TO "service_role";

REVOKE ALL ON TABLE "public"."recommendations" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."recommendations" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."recommendations" TO "service_role";

REVOKE ALL ON TABLE "public"."referrals" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."referrals" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."referrals" TO "service_role";

REVOKE ALL ON TABLE "public"."saved_programs" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."saved_programs" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."saved_programs" TO "service_role";

REVOKE ALL ON TABLE "public"."service_categories" FROM "anon";

GRANT SELECT ON TABLE "public"."service_categories" TO "anon";

REVOKE ALL ON TABLE "public"."service_categories" FROM "authenticated";

GRANT SELECT ON TABLE "public"."service_categories" TO "authenticated";

REVOKE ALL ON TABLE "public"."service_categories" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."service_categories" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."service_categories" TO "service_role";

REVOKE ALL ON TABLE "public"."user_profiles" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."user_profiles" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."user_profiles" TO "service_role";

