// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: (),
  fontsize: 11pt,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)

  if title != none {
    align(center)[#block(inset: 2em)[
      #text(weight: "bold", size: 1.5em)[#title]
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)
#show: doc => article(
  title: [Norma y producto punto],
  date: [Invalid Date],
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)


== Objetivos:
<objetivos>
- Definir qué es una norma en álgebra lineal.

- Explicar su importancia en la teoría de vectores.

- Mostrar las propiedades principales de las normas.

- Aplicar normas en ejemplos gráficos.

== Normas inducidas por productos internos
<normas-inducidas-por-productos-internos>
Dado un espacio vectorial $bb(R)^n$ con un producto interno \$ , $,$$angle.l upright(bold(v)) , upright(bold(w)) angle.r = sum_(i = 1)^n v_i w_i$\$

tomando $upright(bold(v)) = upright(bold(w))$ la norma inducida por el producto interno es:

$ lr(||) upright(bold(v)) lr(||) = sqrt(angle.l upright(bold(v)) , upright(bold(v)) angle.r) = sqrt(sum_(i = 1)^n v_i^2) $

== Importancia de la Norma en Álgebra Lineal
<importancia-de-la-norma-en-álgebra-lineal>
La norma permite cuantificar el tamaño de un vector.

Es esencial en la normalización de vectores (vectores unitarios).

Se usa en diversas aplicaciones, desde análisis de datos hasta mecánica clásica.

#horizontalrule

```python
import matplotlib.pyplot as plt
import numpy as np

vector = np.array([3, 4])
origin = np.array([0, 0])

plt.quiver(*origin, *vector, scale=1, scale_units='xy', angles='xy')
plt.xlim(0, 5)
plt.ylim(0, 5)
plt.axhline(0, color='black',linewidth=0.5)
plt.axvline(0, color='black',linewidth=0.5)
plt.title("Vector y su Norma")
plt.grid(True)
plt.show()
```

#box(image("presentacion_files/figure-typst/cell-2-output-1.svg"))

#horizontalrule

== Propiedades de las Normas (I)
<propiedades-de-las-normas-i>
#strong[Propiedad 1: No negatividad]

$ lr(||) upright(bold(v)) lr(||) gt.eq 0 quad upright("y") quad lr(||) upright(bold(v)) lr(||) = 0 thin upright("si y sólo si") thin upright(bold(v)) = 0 $

#strong[Propiedad 2: Homogeneidad]

$ lr(||) c upright(bold(v)) lr(||) = lr(|c|) dot.op lr(||) upright(bold(v)) lr(||) $

== Propiedades de las Normas (II)
<propiedades-de-las-normas-ii>
#strong[Propiedad 3: Desigualdad triangular]

$ lr(||) upright(bold(u)) + upright(bold(v)) lr(||) lt.eq lr(||) upright(bold(u)) lr(||) + lr(||) upright(bold(v)) lr(||) $

#horizontalrule

```python
import matplotlib.pyplot as plt
import numpy as np

vector_u = np.array([2, 3])
vector_v = np.array([3, 1])
origin = np.array([0, 0])

plt.quiver(*origin, *vector_u, color='b', scale=1, scale_units='xy', angles='xy', label='u')
plt.quiver(*origin, *vector_v, color='r', scale=1, scale_units='xy', angles='xy', label='v')
plt.quiver(*origin, *(vector_u + vector_v), color='g', scale=1, scale_units='xy', angles='xy', label='u+v')

plt.xlim(0, 6)  # Ajusta los límites de los ejes para que todos los vectores estén dentro de la vista
plt.ylim(0, 6)
plt.axhline(0, color='black', linewidth=0.5)
plt.axvline(0, color='black', linewidth=0.5)
plt.title("Desigualdad Triangular")
plt.grid(True)
plt.legend()
plt.show()
```

#box(image("presentacion_files/figure-typst/cell-3-output-1.svg"))

#horizontalrule

== Tipos de Normas (I)
<tipos-de-normas-i>
Norma Euclidiana ( L\_2 ):

$ lr(||) upright(bold(v)) lr(||)_2 = sqrt(sum_(i = 1)^n v_i^2) $

== Tipos de Normas (II)
<tipos-de-normas-ii>
Norma ( L\_1 ) (Manhattan):

$ lr(||) upright(bold(v)) lr(||)_1 = sum_(i = 1)^n lr(|v_i|) $

```python
vector = np.array([3, 4])

plt.plot([0, 3], [0, 4], label="Norma L2")
plt.plot([0, 3], [0, 0], 'r--', label="Manhattan X")
plt.plot([3, 3], [0, 4], 'r--', label="Manhattan Y")
plt.title("Comparación de Normas L1 y L2")
plt.grid(True)
plt.legend()
plt.show()
```

#box(image("presentacion_files/figure-typst/cell-4-output-1.svg"))

== Norma $L_oo$ (Norma Máxima)
<norma-l_infty-norma-máxima>
$ lr(||) upright(bold(v)) lr(||)_oo = max_i lr(|v_i|) $

== Aplicaciones de las Normas
<aplicaciones-de-las-normas>
Aplicaciones comunes:

- Normalización de vectores para algoritmos de aprendizaje automático.

- Cálculo de distancias entre puntos en análisis de datos.

- Aplicaciones en física, como la mecánica y la óptica.

#horizontalrule

```python
import matplotlib.pyplot as plt
import numpy as np

vector = np.array([3, 4])
origin = np.array([0, 0])

# Normalización del vector
vector_normalizado = vector / np.linalg.norm(vector)

# Dibujamos el vector normalizado
plt.quiver(*origin, *vector_normalizado, color='b', scale=1, scale_units='xy', angles='xy', label='Vector Normalizado')

# Ajustamos los límites de los ejes para que todo el vector esté en la vista
plt.xlim(-1, 2)  # Los valores pueden ajustarse según sea necesario
plt.ylim(-1, 2)
plt.axhline(0, color='black', linewidth=0.5)
plt.axvline(0, color='black', linewidth=0.5)
plt.title("Normalización de un Vector")
plt.grid(True)
plt.legend()
plt.show()
```

#box(image("presentacion_files/figure-typst/cell-5-output-1.svg"))

#horizontalrule

== Calculo de normas
<calculo-de-normas>
=== Norma $L_1$ (Manhattan) en Logística
<norma-l_1-manhattan-en-logística>
#strong[Contexto:] Un repartidor debe viajar entre dos puntos de una ciudad que sigue una disposición en cuadrícula. La ciudad solo permite moverse en dirección horizontal o vertical.

Dado un vector de desplazamiento $upright(bold(d)) = (3 , 7)$, calcula la norma $L_1$ y proporciona una interpretación en términos de distancia recorrida.

$ lr(||) upright(bold(d)) lr(||)_1 = lr(|3|) + lr(|7|) = 3 + 7 = 10 $

#horizontalrule

#strong[Interpretación:] La norma $L_1$ en este contexto es la distancia total recorrida por el repartidor, sumando los movimientos horizontales y verticales. Representa la "distancia de taxi" o la distancia efectiva en una ciudad con una cuadrícula.

#horizontalrule

== Norma $L_2$ (Euclidiana) en Física
<norma-l_2-euclidiana-en-física>
#strong[Contexto:] En un sistema físico, la norma Euclidiana se utiliza para calcular la magnitud de la velocidad de un objeto que se mueve en el espacio tridimensional.

Dado el vector de velocidad $upright(bold(v)) = (2 , 3 , 6)$, calcula la norma $L_2$ y proporciona una interpretación en términos de la magnitud de la velocidad.

$ lr(||) upright(bold(v)) lr(||)_2 = sqrt(2^2 + 3^2 + 6^2) = sqrt(4 + 9 + 36) = sqrt(49) = 7 $

#horizontalrule

#strong[Interpretación:] La norma $L_2$ en este contexto te dará la magnitud de la velocidad, lo que indica la rapidez con la que el objeto se está moviendo en el espacio. Esta magnitud es la velocidad total en metros por segundo.

#horizontalrule

=== Norma $L_oo$ (Máxima) en Control de Calidad
<norma-l_infty-máxima-en-control-de-calidad>
#strong[Contexto:] En control de calidad, la norma $L_oo$ se utiliza para detectar la desviación máxima de un conjunto de datos.

Dado el vector de errores de medición $upright(bold(e)) = (- 0.1 , 0.05 , - 0.2 , 0.15)$, calcula la norma $L_oo$ y proporciona una interpretación en términos de la desviación máxima.

$ lr(||) upright(bold(e)) lr(||)_oo = max { lr(|- 0.1|) , lr(|0.05|) , lr(|- 0.2|) , lr(|0.15|) } $ $ = max { 0.1 , 0.05 , 0.2 , 0.15 } = 0.2 $

#horizontalrule

#strong[Interpretación:] La norma $L_oo$ te da la desviación más grande en valor absoluto, lo que indica cuál es el mayor error de medición en el conjunto de datos. Este valor es importante para evaluar el peor caso en términos de precisión.

#horizontalrule

== Distancia $L_1$ (Manhattan)
<distancia-l_1-manhattan>
La distancia $L_1$ entre dos puntos $upright(bold(x)) = (x_1 , x_2)$ y $upright(bold(y)) = (y_1 , y_2)$ es:

$ d_(L_1) (upright(bold(x)) , upright(bold(y))) = lr(|x_1 - y_1|) + lr(|x_2 - y_2|) $

#horizontalrule

Esta distancia sigue caminos horizontales y verticales, como en una cuadrícula.

```python
import numpy as np
import matplotlib.pyplot as plt

# Definir puntos
x = np.array([1, 2])
y = np.array([4, 6])

# Calcular distancia L1
L1_distance = np.sum(np.abs(x - y))

# Gráfico del camino L1
plt.plot([x[0], y[0]], [x[1], x[1]], 'r--', label="Desplazamiento Horizontal")
plt.plot([y[0], y[0]], [x[1], y[1]], 'r--', label="Desplazamiento Vertical")
plt.scatter([x[0], y[0]], [x[1], y[1]], c='b')
plt.text(x[0], x[1], 'Punto A', fontsize=12)
plt.text(y[0], y[1], 'Punto B', fontsize=12)
plt.title(f"Distancia $L_1$: {L1_distance}")
plt.grid(True)
plt.legend()
plt.show()
```

#box(image("presentacion_files/figure-typst/cell-6-output-1.svg"))

#horizontalrule

== Distancia $L_2$ (Euclidiana)
<distancia-l_2-euclidiana>
La distancia $L_2$ entre dos puntos $upright(bold(x)) = (x_1 , x_2)$ y $upright(bold(y)) = (y_1 , y_2)$ es:

$ d_(L_2) (upright(bold(x)) , upright(bold(y))) = sqrt((x_1 - y_1)^2 + (x_2 - y_2)^2) $

Esta distancia representa la línea recta más corta entre los dos puntos.

#horizontalrule

```python
# Calcular distancia L2
L2_distance = np.sqrt(np.sum((x - y) ** 2))

# Gráfico del camino L2
plt.plot([x[0], y[0]], [x[1], y[1]], 'g-', label="Línea Recta")
plt.scatter([x[0], y[0]], [x[1], y[1]], c='b')
plt.text(x[0], x[1], 'Punto A', fontsize=12)
plt.text(y[0], y[1], 'Punto B', fontsize=12)
plt.title(f"Distancia $L_2$: {L2_distance}")
plt.grid(True)
plt.legend()
plt.show()
```

#box(image("presentacion_files/figure-typst/cell-7-output-1.svg"))

#horizontalrule

== Distancia $L_oo$ (Máxima)
<distancia-l_infty-máxima>
La distancia $L_oo$ entre dos puntos $upright(bold(x)) = (x_1 , x_2)$ y $upright(bold(y)) = (y_1 , y_2)$ es:

$ d_(L_oo) (upright(bold(x)) , upright(bold(y))) = max (lr(|x_1 - y_1|) , lr(|x_2 - y_2|)) $

#horizontalrule

Esta distancia se enfoca en el mayor desplazamiento en cualquier coordenada.

```python
# Calcular distancia Linf
Linf_distance = np.max(np.abs(x - y))

# Gráfico del camino Linf
plt.plot([x[0], y[0]], [x[1], x[1]], 'r--', label="Desplazamiento Horizontal")
plt.plot([y[0], y[0]], [x[1], y[1]], 'r--', label="Desplazamiento Vertical")
plt.scatter([x[0], y[0]], [x[1], y[1]], c='b')
plt.text(x[0], x[1], 'Punto A', fontsize=12)
plt.text(y[0], y[1], 'Punto B', fontsize=12)
plt.title(f"Distancia $L_\infty$: {Linf_distance}")
plt.grid(True)
plt.legend()
plt.show()
```

#block[
```
<>:10: SyntaxWarning: invalid escape sequence '\i'
<>:10: SyntaxWarning: invalid escape sequence '\i'
/tmp/ipykernel_21305/1327578443.py:10: SyntaxWarning: invalid escape sequence '\i'
  plt.title(f"Distancia $L_\infty$: {Linf_distance}")
```

]
#box(image("presentacion_files/figure-typst/cell-8-output-2.svg"))

#horizontalrule

== Comparación de las distancias
<comparación-de-las-distancias>
Podemos comparar las tres distancias calculadas entre los puntos $A$ y $B$:

- Distancia $L_1$: $lr(|x_1 - y_1|) + lr(|x_2 - y_2|)$
- Distancia $L_2$: $sqrt((x_1 - y_1)^2 + (x_2 - y_2)^2)$
- Distancia $L_oo$: $max (lr(|x_1 - y_1|) , lr(|x_2 - y_2|))$

Cada norma mide la distancia de una forma diferente. La distancia $L_1$ suma las diferencias en las coordenadas, la distancia $L_2$ mide la línea recta más corta, y la distancia $L_oo$ se enfoca en el mayor desplazamiento.

== Como te imaginas que seria una circunferencia en las diferentes distancias?
<como-te-imaginas-que-seria-una-circunferencia-en-las-diferentes-distancias>
#strong[Definicio de circunferencia] Una circunferencia es el lugar geométrico de los puntos del plano cuya distancia a otro punto fijo, llamado centro, es constante.

#horizontalrule

```python
plt.figure(figsize=(6, 6))

# Rango de ángulos para dibujar las "circunferencias"
theta = np.linspace(0, 2 * np.pi, 100)

# Función para dibujar circunferencia bajo norma L1
x_L1 = np.abs(np.cos(theta)) + np.abs(np.sin(theta))  # L1 suma de valores absolutos
x1 = np.cos(theta) / x_L1
y1 = np.sin(theta) / x_L1

# Función para dibujar circunferencia bajo norma L2
x2 = np.cos(theta)
y2 = np.sin(theta)

# Dibujar un cuadrado para la norma L_inf (Máxima)
x3 = np.array([-1, 1, 1, -1, -1])
y3 = np.array([-1, -1, 1, 1, -1])

# Dibujar las tres circunferencias en el mismo plano cartesiano
plt.plot(x1, y1, label='$L_1$', color='r')
plt.plot(x2, y2, label='$L_2$', color='g')
plt.plot(x3, y3, label='$L_\infty$', color='b')

# Configuraciones del gráfico
plt.gca().set_aspect('equal')
plt.title('Comparación de normas $L_1$, $L_2$ y $L_\infty$')
plt.grid(True)
plt.legend()
plt.xlim([-1.5, 1.5])
plt.ylim([-1.5, 1.5])

# Mostrar la figura
plt.show()
```

#block[
```
<>:22: SyntaxWarning: invalid escape sequence '\i'
<>:26: SyntaxWarning: invalid escape sequence '\i'
<>:22: SyntaxWarning: invalid escape sequence '\i'
<>:26: SyntaxWarning: invalid escape sequence '\i'
/tmp/ipykernel_21305/1189076720.py:22: SyntaxWarning: invalid escape sequence '\i'
  plt.plot(x3, y3, label='$L_\infty$', color='b')
/tmp/ipykernel_21305/1189076720.py:26: SyntaxWarning: invalid escape sequence '\i'
  plt.title('Comparación de normas $L_1$, $L_2$ y $L_\infty$')
```

]
#box(image("presentacion_files/figure-typst/cell-9-output-2.svg"))
