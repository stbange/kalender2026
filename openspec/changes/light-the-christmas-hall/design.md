## Light sources

Use the engine's forward renderer and its eight point-light slots for the hall. Candle chandeliers, festoon lights, tree bulbs and the fire illuminate nearby surfaces and moving visitors. Give the visible filaments and colored glass their own emissive materials. Keep the numbered arches legible from the floor.

## Cast shadows and the view outside

Only the fire and the candle chandelier above the entrance cast shadows. Project static scene triangles from each point source onto the floor. Store the two masks in separate nibbles of the external floor texture's alpha byte. The forward shader attenuates each lamp independently. Moving bodies and articulated joints project their current mesh onto the same receiver from the stronger of those two sources. The projecting mantel also shades the chimney breast above the fire. This keeps the hall within eight local lights and avoids per-eye shadow-map updates in VR.

Use open timber sashes at clerestory height and eye level. Generate the stars from world-space view direction and place the snow banks, firs and mountain silhouettes at different distances. When the player sidesteps, the scenery shifts across the distant stars and the frames move in the foreground.

## Hearth and tree

The west fireplace fits between the two existing portals. Recess the firebox behind a brick surround and furnish the mantel with evergreen, candles and stockings. Flames rise through the logs in overlapping layers above a permanent ember bed. Render reduced motion with a steady pose and steady light.

Build the tree from several whorls of uneven branches with textured needle sprays. Wind a cable through the outer tips, add colored bulbs and hang reflective ornaments below the branches. Generate the models, textures and original CC BY 4.0 art from deterministic local source.

## Presentation and validation

Keep the HUD at display resolution and WebXR on the headset's native eye buffers. Test the actual WebGL scene at the entry, beside the hearth and at the gallery doors. Check animation, reduced motion and loose asset packaging through the existing test pipeline.
