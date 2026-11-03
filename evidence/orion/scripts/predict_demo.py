import numpy as np
import akida

model = akida.Model("/workspace/brainchip_devhub/akida1/model_zoo/plant_village/pretrained_models/akidanet_plant_village_qat.fbz")
print("layers:", len(model.layers), "| input shape:", model.input_shape, "| output shape:", model.output_shape)

devices = akida.devices()
if devices:
    model.map(devices[0], mode=akida.MapMode.AllNps, hw_only=True)
    print("running on:", devices[0].desc)
else:
    print("no board found, running on the software device")

# Random noise images, so the class ids below mean nothing. Use real images of the right size.
images = np.random.randint(0, 256, size=(4,) + tuple(model.input_shape), dtype=np.uint8)
out = model.predict(images)
print("predictions (class ids):", out.squeeze().argmax(axis=-1))
