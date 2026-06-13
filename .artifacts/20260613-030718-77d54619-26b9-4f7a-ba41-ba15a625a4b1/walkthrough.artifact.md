# Piano Keys Realism Enhancements

I have added several visual effects to the piano keys to make them look more like physical, 3D objects with realistic lighting.

## Changes

### [Black Keys](file:///home/keyturn/StudioProjects/empyreal_keys_old/lib/components/piano_keyboard/black_keys.dart)
- **Sharp Edge Shimmer**: Added a 1.5px vertical specular highlight on the left side to simulate light hitting a polished edge.
- **Top Gloss Gradient**: Added a radial gloss at the top to give the key a "plastic/ebony" sheen.
- **Bevel Highlight**: A subtle horizontal line at the top edge to define the corner.
- **Improved Shadows**: Increased shadow depth and adjusted the gradient to a deeper "ebony" palette.

### [White Keys](file:///home/keyturn/StudioProjects/empyreal_keys_old/lib/components/piano_keyboard/white_keys.dart)
- **Ivory Gradient**: Changed the flat white to a subtle vertical gradient (White to #F5F5F5).
- **Bevel Highlight**: Added a bright horizontal highlight at the top to simulate a rounded edge.
- **Top-Left Shimmer**: Added a soft radial shimmer in the top-left corner.
- **Ambient Occlusion**: Added a soft dark gradient at the bottom to simulate the gap between the keys and the piano body.

## Verification
- Code has been updated to use hardware-accelerated gradients and shadows.
- Performance remains high as no heavy filters (like BackdropBlur) were used.
