# Atlas Typography Audition

Date: 2026-04-16

## Scope

This pass compared the previous SF Rounded-led typography against two Atlas-native alternatives inside the app shell:

- Avenir Next for display, metrics, labels, and major headings, with SF retained for longer body copy.
- IBM Plex Sans across the typography roles, bundled locally under the Open Font License.

The in-app audition screen is hidden by default and appears only when launched with `-AtlasTypographyAudition` or `ATLAS_TYPOGRAPHY_AUDITION=1`. The production default is now the Avenir Next + SF hybrid.

## Simulator Captures

- Avenir Next: `/Users/donghokang/Developer/Atlas/output/typography-audition/atlas-typography-avenir.jpg`
- IBM Plex Sans: `/Users/donghokang/Developer/Atlas/output/typography-audition/atlas-typography-plex.jpg`

## Assessment

Avenir Next is the stronger next direction for Atlas. It keeps the product warm and premium without making the clinical tracking surfaces feel cold. The heavier display shapes give "Atlas" more brand presence, metric cards stay confident at small sizes, and body copy remains readable because the audition keeps SF for longer explanatory text.

IBM Plex Sans makes Atlas feel more technical and credible, but it also flattens the emotional tone. It is useful for dense review/reporting surfaces, but as a global app voice it pushes the product closer to an enterprise dashboard than a calm personal health companion.

## Recommendation

Ship the Avenir Next + SF hybrid:

- Use Avenir Next Bold/Demi Bold for the Atlas wordmark, screen titles, card titles, metric values, and uppercase labels.
- Keep SF for explanatory body copy, footnotes, and longer paragraphs.
- Revisit IBM Plex Sans later only if the app adds a separate clinician/export/reporting mode that needs a more analytical texture.

## Verification

- Built the Atlas iOS simulator target successfully.
- Launched Avenir and IBM Plex audition variants from the fresh build product.
- Relaunched without the audition flag and confirmed the normal Today screen appears.
