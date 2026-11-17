# Official sources for the prototype seed

Reviewed November 16, 2026. These are concise directory summaries, not determinations of eligibility. Full program rules and availability remain with the organizations. Missing contact fields remain NULL. No logos or photographs were copied.

| Organization and program | Verified sources | Assistance destination |
| --- | --- | --- |
| U.S. Department of Veterans Affairs: VA Health Care | [How to apply](https://www.va.gov/health-care/how-to-apply/), [eligibility](https://www.va.gov/health-care/eligibility/) | [Online VA Form 10-10EZ](https://www.va.gov/forms/10-10ez/apply-va-healthcare/) — Apply |
| California Department of Veterans Affairs: CalVet Home Loans | [California government service listing](https://www.ca.gov/departments/163/services/64/), [department and contact listing](https://www.ca.gov/departments/163/) | [CalVet pre-approval portal](https://calvet.zipforhome.com/) — Apply; the third-party portal is explicitly linked by CA.gov |
| Wounded Warrior Project: Veteran Registration and Support Services | [Current registration information](https://www.woundedwarriorproject.org/programs/wwp-registration), [background](https://www.woundedwarriorproject.org/mission) | [Official warrior registration form](https://www.woundedwarriorproject.org/programs/wwp-registration/alumni) — Apply; family registration is separate on the information page |
| Operation Homefront: Critical Financial Assistance | [Program overview](https://operationhomefront.org/critical-financial-assistance/), [eligibility](https://operationhomefront.org/cfa-eligibility/), [process](https://operationhomefront.org/cfa-process/), [background](https://operationhomefront.org/about-us/) | [CFA process instructions](https://operationhomefront.org/cfa-process/) — How to Get Assistance; official instructions lead to the MyOH account portal |
| Swords to Plowshares: Bay Area Housing Assistance | [Housing services and addresses](https://www.swords-to-plowshares.org/services/housing), [intake and general eligibility](https://www.swords-to-plowshares.org/get-care), [history](https://www.swords-to-plowshares.org/about) | [Housing contact instructions](https://www.swords-to-plowshares.org/services/housing) — How to Get Assistance; the Get Care page offers contact/intake rather than a direct housing application |

## Details affecting the demonstration

- VA eligibility has service-length and discharge rules with exceptions. The seed does not attempt to encode every exception.
- CalVet's loan phone is distinct from its general department phone. The CalVet homepage could not be fetched by the research tool; the California government listings and their linked pre-approval portal supplied verification.
- WWP's current registration page describes broader access than older injury-only summaries. The seed follows the current page and directs documentation questions to WWP.
- Operation Homefront's current process page lists applications from the 1st through the 10th each month, with an 11:59 PM CST closing time. Its application portal is not presented as a direct application form in OneVet. Review the current instructions; being eligible does not guarantee funding.
- Swords to Plowshares serves the Bay Area. The schema's local city rows identify San Francisco and Oakland; the program description states the wider Bay Area scope. Both service-center addresses were found on its official housing page. General intake access does not establish eligibility for each housing program.

## Mapping to the existing schema

- `organizations`: name, constrained organization type, brief description + background paragraphs, official website, verified phone/email; the Swords description includes verified service-center addresses.
- `programs`: one named program per organization, description + process paragraphs, eligibility notes, official source/instructions in `website_url`, direct form in `application_url` only when verified, phone, published status, verification date.
- `service_categories` + `program_categories`: four categories (Housing shared by two programs).
- `program_service_areas`: nationwide, California statewide, or the verified Bay Area cities, subject to the existing constraints.
- `eligibility_criteria`: one sourced supplementary summary per seeded program.

Unknown contact values remain empty, and images are omitted rather than inventing addresses, emails, or logos. Re-running the seed preserves unrelated records and does not change access policies.
