import tensorflow as tf

converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.int8]
# Provide a representative dataset for calibration
def representative_data_gen():
    for image, _ in sample_dataset.take(100):
        yield [image]
converter.representative_dataset = representative_data_gen
tflite_model = converter.convert()
with open('liveness.tflite', 'wb') as f:
    f.write(tflite_model)