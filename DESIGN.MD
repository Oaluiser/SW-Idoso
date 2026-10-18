---
version: alpha
name: Evergreen Concierge
description: >
  Warm, relationship-first SaaS marketing system extracted from a reference
  landing page. Cream-to-mint light hero, deep evergreen body sections,
  pale mint cards, and a single electric-lime accent for every primary action.
colors:
  primary: "#0C3B31"          # Evergreen — dark section surfaces, primary text on light
  primary-deep: "#0A2E22"     # Headline ink on light backgrounds
  primary-raised: "#0A4137"   # Slightly lifted evergreen panel (first dark section)
  secondary: "#85A7A0"        # Sage — hairline borders, outline buttons, muted UI
  tertiary: "#E3F124"         # Electric lime — CTAs, links on dark, marquee band
  tertiary-hover: "#D2E01A"
  neutral: "#FCF6EA"          # Cream — top of hero gradient, page warmth
  surface-mint: "#E8F4F0"     # Bottom of hero gradient, card tops
  surface-lime-wash: "#E5EFB2" # Card bottoms (mint → lime wash)
  surface-card: "#FFFFFF"     # Floating UI chips / message bubbles
  on-primary: "#E3FDFA"       # Headline text on evergreen
  on-primary-muted: "#C5D9D5" # Body text on evergreen
  on-surface: "#112A26"       # Headline text on mint cards
  on-surface-muted: "#5E7A74" # Body text on light surfaces
  on-tertiary: "#0C3B31"      # Text on lime buttons
  input-border: "#BFC6C6"
typography:
  headline-display:
    fontFamily: Instrument Sans
    fontSize: 56px
    fontWeight: 500
    lineHeight: 1.05
    letterSpacing: "-0.03em"
  headline-lg:
    fontFamily: Instrument Sans
    fontSize: 40px
    fontWeight: 500
    lineHeight: 1.1
    letterSpacing: "-0.025em"
  headline-md:
    fontFamily: Instrument Sans
    fontSize: 26px
    fontWeight: 500
    lineHeight: 1.15
    letterSpacing: "-0.02em"
  headline-marquee:
    fontFamily: Instrument Sans
    fontSize: 40px
    fontWeight: 500
    lineHeight: 1
    letterSpacing: "-0.02em"
  body-lg:
    fontFamily: Instrument Sans
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.55
  body-md:
    fontFamily: Instrument Sans
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.55
  body-sm:
    fontFamily: Instrument Sans
    fontSize: 12px
    fontWeight: 400
    lineHeight: 1.5
  label-lg:
    fontFamily: Instrument Sans
    fontSize: 18px
    fontWeight: 500
    lineHeight: 1.3
  label-md:
    fontFamily: Instrument Sans
    fontSize: 14px
    fontWeight: 500
    lineHeight: 1
  label-sm:
    fontFamily: Instrument Sans
    fontSize: 11px
    fontWeight: 500
    lineHeight: 1.2
rounded:
  none: 0px
  sm: 4px
  md: 8px
  lg: 16px
  xl: 24px
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 48px
  2xl: 80px
  3xl: 120px
  gutter: 16px
  margin: 24px
  container-max: 1180px
  content-narrow: 720px
components:
  button-primary:
    backgroundColor: "{colors.tertiary}"
    textColor: "{colors.on-tertiary}"
    typography: "{typography.label-md}"
    rounded: "{rounded.sm}"
    padding: 10px 20px
    height: 40px
  button-primary-hover:
    backgroundColor: "{colors.tertiary-hover}"
  button-secondary:
    backgroundColor: "{colors.neutral}"
    textColor: "{colors.primary}"
    typography: "{typography.label-md}"
    rounded: "{rounded.sm}"
    padding: 10px 20px
    height: 40px
  button-nav:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.sm}"
    padding: 6px 12px
  button-card-outline:
    backgroundColor: "{colors.surface-mint}"
    textColor: "{colors.on-surface}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.sm}"
    padding: 4px 12px
  link-on-dark:
    textColor: "{colors.tertiary}"
    typography: "{typography.label-lg}"
  section-dark:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.xl}"
    padding: 80px
  hero-headline:
    textColor: "{colors.primary-deep}"
    typography: "{typography.headline-display}"
  hero-subhead:
    textColor: "{colors.on-surface-muted}"
    typography: "{typography.body-md}"
  section-dark-raised:
    backgroundColor: "{colors.primary-raised}"
    textColor: "{colors.on-primary-muted}"
    rounded: "{rounded.xl}"
    padding: 80px
  feature-card:
    backgroundColor: "{colors.surface-mint}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.md}"
    padding: 32px
  floating-chip:
    backgroundColor: "{colors.surface-card}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body-sm}"
    rounded: "{rounded.md}"
    padding: 12px 16px
  photo-tag:
    backgroundColor: "{colors.surface-lime-wash}"
    textColor: "{colors.on-surface}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.full}"
    padding: 4px 12px
  input-field:
    backgroundColor: "{colors.surface-card}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body-md}"
    rounded: "{rounded.sm}"
    padding: 8px 12px
    height: 36px
  marquee-band:
    backgroundColor: "{colors.tertiary}"
    textColor: "{colors.primary}"
    typography: "{typography.headline-marquee}"
    height: 72px
---

# Evergreen Concierge — Design System

> Extracted from a single desktop screenshot of a relationship-management SaaS
> landing page. Hex values were sampled from the image (JPEG-compressed, so
> treat them as ±2–3% accurate). The typeface is an **unverified stand-in** —
> confirm it from the live site's CSS before shipping.

## Overview

A quiet, trustworthy, "concierge" feel for a B2B tool about personal client
relationships. The emotional target is *warm professionalism*: the competence of
a private bank with the friendliness of a handwritten note.

Three moves define the system:

1. **Light-to-dark narrative.** The page opens on a soft cream→mint hero, then
   drops into a long run of deep evergreen sections, and closes with a loud lime
   marquee. Light = welcome, dark = substance, lime = action.
2. **One accent, used sparingly but loudly.** Electric lime is the only saturated
   color. It marks primary CTAs, link-style feature toggles on dark, and the
   closing marquee. Nothing else competes with it.
3. **Human proof layered with product proof.** Real photography of people is
   overlaid with small white UI chips (a gift message, a birthday reminder) so
   every image shows *the product doing something personal*.

Audience: account managers, advisors, sales and client-success teams. Density is
low; whitespace is generous; copy is short.

## Colors

The palette is two families — evergreen and mint/cream — plus a single lime accent.

- **Evergreen (#0C3B31, `primary`):** The body of the site. Large dark section
  panels with rounded top corners stack on each other. Also used as ink for UI
  text on light surfaces. A slightly lifted variant (#0A4137) separates
  adjacent dark sections; the step is subtle by design.
- **Deep Ink (#0A2E22, `primary-deep`):** Display headlines on the light hero.
  Never pure black.
- **Sage (#85A7A0, `secondary`):** Hairline borders on cards, outline buttons,
  decorative contour lines in backgrounds.
- **Electric Lime (#E3F124, `tertiary`):** The only call to action color.
  Primary buttons, feature-list links and "+" toggles on evergreen, the
  waitlist submit button, the final marquee band.
- **Cream (#FCF6EA, `neutral`) → Mint (#E8F4F0):** Hero gradient, top to bottom.
  Gives warmth without going beige.
- **Mint → Lime Wash (#E8F4F0 → #E5EFB2):** Feature cards fade from cool mint at
  the top to a faint lime glow at the bottom, tying them to the accent.
- **Text on evergreen:** #E3FDFA for headlines, #C5D9D5 for body. Never pure white.

## Typography

One neutral grotesk family carries everything; hierarchy comes from size and
tight tracking, not weight contrast.

- **Display & headlines:** Medium (500) weight, tight negative tracking
  (−0.02 to −0.03em), line-height ~1.05–1.15. Headlines are short, centered on
  the hero and section intros, left-aligned in split layouts.
- **Body:** Regular 400, small (12–16px), generous line-height, muted color.
  Body copy is deliberately understated so headlines and photos lead.
- **Labels:** Medium 500 for buttons and links. No uppercase, no letter-spaced
  eyebrows.
- **Stand-in font:** *Instrument Sans* (Google Fonts) approximates the
  reference. Alternatives with a similar feel: *Geist*, *General Sans*,
  *Hanken Grotesk*. Inspect the live site to confirm the original.

## Layout

- **Container:** ~1180px max width, centered. Hero copy constrained to ~720px.
- **Hero:** centered headline (2 lines), one-line subhead, two buttons side by
  side (lime primary + outline secondary), then a large rounded photo with a
  floating message chip overlapping its lower-left corner.
- **Split section:** product screenshot left (~45%), headline + paragraph +
  accordion-style lime link list right.
- **Feature grid:** 2×2 cards with equal heights and a narrow (~12–16px) gutter.
  Each card: centered title, one-line description, small outline "Try" button,
  then an illustration that bleeds off the bottom edge.
- **Closing section:** centered form (first/last name side by side, email full
  width, full-width lime submit) surrounded by photos scattered on curved
  connector lines, each labeled with a pill tag.
- **Spacing:** 8px base. Sections breathe with 80–120px vertical padding.
  Card interiors use 32px.

## Elevation & Depth

Depth comes from **tonal layering and overlap**, not heavy shadows.

- Dark sections sit on each other like stacked sheets, each with rounded top
  corners and a tiny tone shift.
- White floating chips over photos use a soft, wide shadow
  (`0 8px 24px rgba(12,59,49,0.12)`), the only real shadow in the system.
- Large photos and product screenshots get a faint 1px light border and a
  shallow shadow so they read as "placed objects".
- Backgrounds carry thin sage contour lines (topographic/flowing curves) at low
  opacity for atmosphere. Never flat fills alone.

## Shapes

Soft but not bubbly.

- **4px** on buttons and inputs: crisp, businesslike.
- **8px** on cards, chips, photos.
- **24px** on the top corners of full-width dark sections.
- **Full pill** only for photo tags and small status labels.
- Avatars are circles with a white ring.

## Components

- **Primary button:** lime fill, evergreen text, 4px radius, 40px tall. Hover
  darkens the lime slightly; no glow, no gradient.
- **Secondary button:** transparent with a 1px evergreen border, same size.
- **Nav button:** small, evergreen fill, light text, top right. The nav itself
  is just wordmark left and this button right.
- **Feature link list (on dark):** lime text links with a lime "+" at the far
  right, separated by vertical spacing only. Behaves as an accordion.
- **Feature card:** mint→lime-wash vertical gradient, 1px sage border, 8px radius,
  centered text, illustration cropped at the bottom.
- **Floating chip:** white card with avatar, one or two lines of sentence-case
  text, optional thumbnail. Used to show "the product in action" on photos.
- **Photo tag:** small pill on a photo naming a feature ("Gift ideas",
  "Check-in cadence"), lime-wash fill.
- **Input:** white, 1px #BFC6C6 border, 4px radius, small placeholder text.
- **Marquee band:** full-bleed lime strip at the very bottom with a repeating
  slogan + circular avatars, scrolling horizontally.
- **Footer:** minimal, centered, small links on evergreen.

## Motion

Not visible in a screenshot; these are recommendations consistent with the tone.

- One orchestrated page-load: hero headline, subhead, buttons, then photo fade
  and rise with ~80ms staggered `animation-delay`.
- Floating chips gently rise in when they enter the viewport.
- Marquee scrolls continuously (~40s loop); pause on hover; respect
  `prefers-reduced-motion`.
- Accordion "+" rotates to "×" on open.

## Do's and Don'ts

- Do keep lime as the only saturated color, and use it only for actions and the
  closing band.
- Do pair every lifestyle photo with a product UI chip so images prove a feature.
- Do use tonal shifts between evergreen sections instead of dividers.
- Do keep body copy short and muted; let headlines carry the message.
- Do keep WCAG AA: lime is for backgrounds with evergreen text, or for large
  text/links on evergreen. Never put lime text on cream or white.
- Don't use pure black or pure white for text.
- Don't add a second accent (no blues, purples or warning-orange in marketing UI).
- Don't use heavy drop shadows, glassmorphism or neon glows.
- Don't mix radii beyond the scale (4 / 8 / 24 / full).
- Don't copy the reference brand's name, logo, slogan or photography. This file
  describes a visual language; bring your own brand and content.