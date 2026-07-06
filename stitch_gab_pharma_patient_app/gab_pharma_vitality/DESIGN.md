---
name: Gab'Pharma Vitality
colors:
  surface: '#eefdf4'
  surface-dim: '#ceded5'
  surface-bright: '#eefdf4'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#e8f7ef'
  surface-container: '#e2f1e9'
  surface-container-high: '#dcece3'
  surface-container-highest: '#d7e6de'
  on-surface: '#111e19'
  on-surface-variant: '#3f4940'
  inverse-surface: '#26332e'
  inverse-on-surface: '#e5f4ec'
  outline: '#6f7a6f'
  outline-variant: '#bec9bd'
  surface-tint: '#076d38'
  primary: '#004f26'
  on-primary: '#ffffff'
  primary-container: '#006a35'
  on-primary-container: '#8fe7a5'
  inverse-primary: '#81d998'
  secondary: '#206b3d'
  on-secondary: '#ffffff'
  secondary-container: '#a8f4b9'
  on-secondary-container: '#287243'
  tertiary: '#5a3f00'
  on-tertiary: '#ffffff'
  tertiary-container: '#785500'
  on-tertiary-container: '#ffcc6c'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#9df6b2'
  primary-fixed-dim: '#81d998'
  on-primary-fixed: '#00210c'
  on-primary-fixed-variant: '#005228'
  secondary-fixed: '#a8f4b9'
  secondary-fixed-dim: '#8cd79f'
  on-secondary-fixed: '#00210d'
  on-secondary-fixed-variant: '#005229'
  tertiary-fixed: '#ffdea7'
  tertiary-fixed-dim: '#ffbb18'
  on-tertiary-fixed: '#271900'
  on-tertiary-fixed-variant: '#5e4200'
  background: '#eefdf4'
  on-background: '#111e19'
  surface-variant: '#d7e6de'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  title-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.1px
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.5px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin-mobile: 16px
---

## Brand & Style

The design system is rooted in the concepts of **trust, vitality, and accessibility**. Designed specifically for the Gabonese pharmaceutical market, it balances professional healthcare standards with a local cultural resonance. 

The visual style is **Corporate / Modern**, heavily influenced by **Material Design 3 (M3)** principles. It utilizes a "tonal surface" approach where the background and containers are tinted with the primary brand color to create a cohesive, calming atmosphere. The interface evokes a sense of reliability for users in Libreville and beyond, ensuring that critical health information is presented with clarity and authority.

Key attributes include:
- **Professionalism:** High-legibility typography and structured layouts.
- **Trustworthy:** A palette of deep greens and soft mints that symbolize growth and health.
- **Efficiency:** A mobile-first 8px grid that ensures rapid interaction and clear navigation.

## Colors

The color palette is built around **Gab'Pharma Green**, a deep, saturated green that provides high contrast for call-to-action elements. 

- **Primary:** Used for key actions, active states, and brand-heavy components.
- **Secondary:** Used for tonal variations in navigation and secondary buttons.
- **Tertiary (Warning/Pending):** An Amber/Gold hue used for pharmacy status (e.g., "Pending Order" or "Pharmacy Closing Soon").
- **Background & Surface:** The application uses a multi-layered light mode. The base background is a pale mint (`#EDFDF4`), while elevated cards use pure white or a secondary surface tint (`#E7F7EE`) to distinguish between content types.
- **Text:** Deep charcoal and muted slate ensure that medication names and dosages are legible even under varying light conditions.

## Typography

This design system utilizes **Inter** exclusively to ensure maximum legibility across different mobile screen densities. 

- **Headlines:** Use a semi-bold weight to establish clear hierarchy for pharmacy names and section headers.
- **Body:** Set to a standard 16px for comfortable reading of medication descriptions.
- **Labels:** Utilized for functional elements like button text, tab bars, and currency (FCFA) displays.
- **Currency Display:** Prices in FCFA should use `title-lg` with a medium weight to emphasize cost without overwhelming the product name.

## Layout & Spacing

The layout is built on a **Fluid Grid** with a strict 8px base unit. 

- **Mobile Layout:** Uses a 4-column grid with 16px side margins and 16px gutters.
- **Vertical Rhythm:** Elements are stacked using increments of 8px (8, 16, 24, 32). Large sections like pharmacy lists or category carousels use 24px spacing to allow the content to breathe.
- **Padding:** Internal card padding is set to 16px to ensure touch targets remain accessible and content is not cramped.

## Elevation & Depth

This design system follows the **Material 3 Tonal Elevation** model. Depth is primarily communicated through color shifts rather than heavy shadows.

- **Level 0 (Background):** Used for the main app canvas (`#EDFDF4`).
- **Level 1 (Cards/Surface):** Used for primary content containers. These use a minimal 2px soft shadow with 4% opacity to create a subtle lift from the background.
- **Level 2 (Interaction):** Active states or modal dialogs use a more pronounced shadow (8px blur, 8% opacity) to signify priority.
- **Overlays:** Navigation bars and bottom sheets use a slight border top (`1px solid #E7F7EE`) and a backdrop blur to maintain context.

## Shapes

The shape language is **friendly yet structured**. 

- **Cards & Containers:** Use a `16px` radius (`rounded-lg` equivalent) to feel approachable and modern.
- **Buttons:** Use a `12px` radius. This distinct difference from the cards helps buttons stand out as interactive elements.
- **Inputs & Search Bars:** Use a `12px` radius to match the buttons, creating a consistent "actionable" language.
- **Chips & Tags:** Use a fully rounded pill shape (32px+) for status indicators like "Open 24/7" or "In Stock."

## Components

### Buttons
- **Primary:** Solid `#006A35` fill with white text. 12px border radius. Minimum height 48px for accessibility.
- **Secondary:** Tonal fill `#E7F7EE` with `#006A35` text. Used for "Add to Cart" or "Call Pharmacy."
- **Tertiary:** Ghost style with text only, used for "View All" or "Dismiss."

### Input Fields
- **Search Bar:** White background, 12px radius, with a subtle 1px border. Includes a leading icon (magnifying glass) and trailing icon (filter).
- **Text Inputs:** Outlined style with a 1px border. The border thickens and changes to primary green when focused.

### Cards
- **Pharmacy Card:** Features a 16px radius, a prominent pharmacy name, status chip (Open/Closed), and distance in km.
- **Product Card:** Focuses on the medicine image, name, and the price clearly displayed in **FCFA**.

### Chips
- **Status Chips:** Small, pill-shaped badges. "Open" uses primary green; "Closed" uses secondary text gray; "24h/24" uses a secondary green tint.

### Lists
- **Medicine Lists:** Uses 16px vertical padding between items with a subtle 1px divider to separate categories.

### Navigation
- **Bottom Navigation:** Fixed at the bottom with 4-5 key destinations: Home, Search, Orders, Profile. Uses the M3 pill-indicator for the active state.