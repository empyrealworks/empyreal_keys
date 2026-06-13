# Enhance Piano Keys Realism

Add shimmer, 3D effects, and realistic lighting to the piano keys while maintaining high performance.

## Proposed Changes

### [Piano Keyboard Components]

#### [black_keys.dart](file:///home/keyturn/StudioProjects/empyreal_keys_old/lib/components/piano_keyboard/black_keys.dart)
- Add a sharp vertical specular highlight ("shimmer") on the left edge.
- Add a top gloss radial gradient.
- Enhance the 3D shadow and bevel effects.
- Adjust colors for a more "ebony" look.

#### [white_keys.dart](file:///home/keyturn/StudioProjects/empyreal_keys_old/lib/components/piano_keyboard/white_keys.dart)
- Add an "ivory" vertical gradient.
- Add a top bevel highlight line to simulate rounded edges.
- Add a bottom ambient occlusion gradient.
- Add a subtle top-left radial shimmer.

## Verification Plan

### Manual Verification
- **Visual Inspection**: Use `render_compose_preview` or inspect on a running device to ensure the keys look "3D" and the shimmer is visible.
- **Performance Test**: Ensure that even with multiple keys pressed, there is no lag in the UI or sound.
