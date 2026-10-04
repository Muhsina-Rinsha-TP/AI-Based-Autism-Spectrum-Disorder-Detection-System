import os
import cv2
import numpy as np
import xml.etree.ElementTree as ET
import tensorflow as tf
import joblib
from tensorflow.keras import layers, models
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.callbacks import EarlyStopping
from sklearn.model_selection import train_test_split
from sklearn.metrics import confusion_matrix, classification_report, f1_score, precision_score, recall_score

# ===============================
# SETTINGS
# ===============================
DATASET_PATH = "ssbd"
VIDEO_PATH = os.path.join(DATASET_PATH, "videos")
ANNOT_PATH = os.path.join(DATASET_PATH, "Annotations")
IMG_SIZE = 128

X = []
y = []

print("Reading dataset...")
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
# ===============================
# PARSE TIME
# ===============================
def parse_time(time_str):
    time_str = time_str.replace("-",":").replace("s","")
    parts = time_str.split(":")
    try:
        return int(parts[0])
    except:
        return 0

# ===============================
# READ VIDEOS
# ===============================
for video_file in os.listdir(VIDEO_PATH):
    if not video_file.endswith(".mp4"):
        continue

    video_id = video_file.replace(".mp4","")
    xml_file = video_id + ".xml"
    xml_path = os.path.join(ANNOT_PATH, xml_file)

    if not os.path.exists(xml_path):
        continue

    print("Processing:", video_file)

    tree = ET.parse(xml_path)
    root = tree.getroot()

    cap = cv2.VideoCapture(os.path.join(VIDEO_PATH,video_file))
    fps = cap.get(cv2.CAP_PROP_FPS)

    behaviours = root.find("behaviours")

    for behaviour in behaviours:
        category = behaviour.find("category").text.lower()
        time_text = behaviour.find("time").text
        start_time = parse_time(time_text)
        frame_start = int(start_time * fps)

        cap.set(cv2.CAP_PROP_POS_FRAMES, frame_start)

        for i in range(20):
            ret, frame = cap.read()
            if not ret:
                break

            frame = cv2.resize(frame,(IMG_SIZE,IMG_SIZE))
            frame = frame / 255.0

            if category == "armflapping":
                label = 0
            elif category == "headbanging":
                label = 1
            elif category == "spinning":
                label = 2
            else:
                continue

            X.append(frame)
            y.append(label)

    cap.release()

X = np.array(X)
y = np.array(y)
print("Total samples:", len(X))

# ===============================
# TRAIN TEST SPLIT
# ===============================
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# ===============================
# DATA AUGMENTATION
# ===============================
datagen = ImageDataGenerator(
    rotation_range=15,
    width_shift_range=0.1,
    height_shift_range=0.1,
    zoom_range=0.1,
    horizontal_flip=True
)
datagen.fit(X_train)

# ===============================
# CUSTOM CNN MODEL (smaller)
# ===============================
model = models.Sequential()

model.add(layers.Input(shape=(IMG_SIZE, IMG_SIZE, 3)))

model.add(layers.Conv2D(32,(3,3),activation='relu'))
model.add(layers.MaxPooling2D(2,2))
model.add(layers.Dropout(0.2))

model.add(layers.Conv2D(64,(3,3),activation='relu'))
model.add(layers.MaxPooling2D(2,2))
model.add(layers.Dropout(0.2))

model.add(layers.Conv2D(128,(3,3),activation='relu'))
model.add(layers.MaxPooling2D(2,2))
model.add(layers.Dropout(0.3))

model.add(layers.Conv2D(128,(3,3),activation='relu'))
model.add(layers.MaxPooling2D(2,2))
model.add(layers.Dropout(0.3))

model.add(layers.Flatten())
model.add(layers.Dense(128, activation='relu'))
model.add(layers.Dropout(0.5))
model.add(layers.Dense(3, activation='softmax'))

# ===============================
# COMPILE MODEL
# ===============================
model.compile(
    optimizer='adam',
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

print(model.summary())

# ===============================
# EARLY STOPPING CALLBACK
# ===============================
early_stop = EarlyStopping(
    monitor='val_accuracy', 
    patience=3, 
    restore_best_weights=True
)

# ===============================
# TRAIN MODEL
# ===============================
history = model.fit(
    datagen.flow(X_train, y_train, batch_size=16),
    epochs=50,
    validation_data=(X_test, y_test),
    callbacks=[early_stop]
)

# ===============================
# EVALUATE MODEL
# ===============================
loss, accuracy = model.evaluate(X_test, y_test, verbose=0)
print("Test Loss:", round(loss, 4))
print("Test Accuracy:", round(accuracy*100, 2), "%")

# PREDICTIONS
y_pred_probs = model.predict(X_test)
y_pred = np.argmax(y_pred_probs, axis=1)

# CONFUSION MATRIX
cm = confusion_matrix(y_test, y_pred)
print("\nConfusion Matrix:\n", cm)

# CLASSIFICATION REPORT
report = classification_report(y_test, y_pred, target_names=['ArmFlapping','HeadBanging','Spinning'])
print("\nClassification Report:\n", report)

# F1, PRECISION, RECALL
f1 = f1_score(y_test, y_pred, average='weighted')
precision = precision_score(y_test, y_pred, average='weighted')
recall = recall_score(y_test, y_pred, average='weighted')

print(f"Weighted F1-score: {f1:.4f}")
print(f"Weighted Precision: {precision:.4f}")
print(f"Weighted Recall: {recall:.4f}")

# ===============================
# SAVE MODEL
# ===============================
joblib.dump(model, "autism_behavior_model.pkl")
print("Model saved successfully as autism_behavior_model.pkl")