"""
EcoLocație - Script de clasificare plante medicinale
Folosește modelul .h5 (TensorFlow/Keras) antrenat pe cele 19 categorii

Utilizare:
  python classify.py <cale_imagine> [model.h5]

Dacă modelul lipsește, se folosește model_cnn_custom.h5 (default).
"""
import sys
import json
import os
import numpy as np

# Clasele (în aceeași ordine ca la antrenare!)
CLASSES = [
    'Aloe Vera',
    'Brusture',
    'Coada soricelului',
    'Coltii babei',
    'Floarea soarelui',
    'Galbenele',
    'Hibiscus',
    'Iasomie',
    'Lavanda',
    'Menta',
    'Musetel',
    'Papadie',
    'Pelin',
    'Rostopasca',
    'Salvie',
    'Sunatoare',
    'Trandafir',
    'Urzica',
    'Valeriana'
]

AVAILABLE_MODELS = [
    'model_cnn_custom.h5',
    'model_densenet121.h5',
    'model_resnet50.h5',
]

DEFAULT_MODEL = 'model_cnn_custom.h5'

def classify(image_path, model_filename):
    """
    Clasifică o imagine folosind modelul .h5 specificat.
    Returnează JSON cu clasa prezisă și confidența.
    """
    try:
        from tensorflow.keras.models import load_model
        from tensorflow.keras.preprocessing.image import load_img, img_to_array

        script_dir = os.path.dirname(os.path.abspath(__file__))
        model_path = os.path.join(script_dir, model_filename)

        if not os.path.exists(model_path):
            raise FileNotFoundError(f'Modelul nu a fost găsit: {model_path}')

        model = load_model(model_path)

        # Determină dimensiunea input-ului din model
        input_shape = model.input_shape[1:3]  # (height, width)

        # Încarcă și preprocesează imaginea
        img = load_img(image_path, target_size=input_shape)
        img_array = img_to_array(img)
        img_array = np.expand_dims(img_array, axis=0)
        img_array = img_array / 255.0  # Normalizare

        # Predicție
        predictions = model.predict(img_array, verbose=0)
        predicted_idx = int(np.argmax(predictions[0]))
        confidence = float(predictions[0][predicted_idx])

        result = {
            'class': CLASSES[predicted_idx],
            'confidence': round(confidence, 4),
            'model_used': model_filename,
            'all_predictions': {
                CLASSES[i]: round(float(predictions[0][i]), 4)
                for i in range(len(CLASSES))
                if predictions[0][i] > 0.01  # Doar cele > 1%
            }
        }

        print(json.dumps(result))

    except Exception as e:
        error = {
            'error': str(e),
            'class': 'Unknown',
            'confidence': 0.0,
            'model_used': model_filename
        }
        print(json.dumps(error))
        sys.exit(1)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(json.dumps({'error': 'Calea imaginii lipsește', 'class': 'Unknown', 'confidence': 0.0}))
        sys.exit(1)

    image_path = sys.argv[1]
    model_filename = sys.argv[2] if len(sys.argv) >= 3 else DEFAULT_MODEL

    if model_filename not in AVAILABLE_MODELS:
        print(json.dumps({'error': f'Model necunoscut: {model_filename}', 'class': 'Unknown', 'confidence': 0.0}))
        sys.exit(1)

    classify(image_path, model_filename)
