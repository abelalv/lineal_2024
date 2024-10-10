import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

# Función para crear los vértices de un cubo (dado)
def crear_dado():
    puntos = np.array([[0, 0, 0], [1, 0, 0], [1, 1, 0], [0, 1, 0],
                       [0, 0, 1], [1, 0, 1], [1, 1, 1], [0, 1, 1]])
    return puntos - 0.5  # Centrar el cubo en el origen

# Función para crear las caras del dado
def crear_caras(puntos):
    caras = [[puntos[j] for j in [0, 1, 2, 3]],  # Cara inferior
             [puntos[j] for j in [4, 5, 6, 7]],  # Cara superior
             [puntos[j] for j in [0, 1, 5, 4]],  # Cara frontal
             [puntos[j] for j in [2, 3, 7, 6]],  # Cara trasera
             [puntos[j] for j in [0, 3, 7, 4]],  # Cara izquierda
             [puntos[j] for j in [1, 2, 6, 5]]]  # Cara derecha
    return caras

# Función de rotación en 3D
def rotacion_3d(puntos, angulo, eje='x'):
    theta = np.radians(angulo)
    if eje == 'x':
        R = np.array([[1, 0, 0],
                      [0, np.cos(theta), -np.sin(theta)],
                      [0, np.sin(theta), np.cos(theta)]])
    elif eje == 'y':
        R = np.array([[np.cos(theta), 0, np.sin(theta)],
                      [0, 1, 0],
                      [-np.sin(theta), 0, np.cos(theta)]])
    elif eje == 'z':
        R = np.array([[np.cos(theta), -np.sin(theta), 0],
                      [np.sin(theta), np.cos(theta), 0],
                      [0, 0, 1]])
    return np.dot(puntos, R.T)

# Función para dibujar el dado
def dibujar_dado(puntos, titulo="Dado"):
    caras = crear_caras(puntos)
    fig = plt.figure()
    ax = fig.add_subplot(111, projection='3d')
    
    # Crear la colección de caras
    ax.add_collection3d(Poly3DCollection(caras, facecolors='cyan', linewidths=1, edgecolors='r', alpha=.25))
    
    # Ajustar límites y etiquetas
    ax.set_xlim([-1, 1])
    ax.set_ylim([-1, 1])
    ax.set_zlim([-1, 1])
    ax.set_xlabel('Eje X')
    ax.set_ylabel('Eje Y')
    ax.set_zlabel('Eje Z')
    plt.title(titulo)
    plt.show()

# Crear el dado original
dado = crear_dado()