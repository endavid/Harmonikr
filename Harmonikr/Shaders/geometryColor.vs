#version 150
in vec3 position;
in vec4 color;
uniform mat4 Pmatrix;
uniform mat4 Vmatrix;
uniform mat4 Mmatrix;
out vec4 vColor;
void main(void) { // pre-built function
    //gl_PointSize = 3.0;
    gl_Position = Pmatrix * Vmatrix * Mmatrix * vec4(position, 1.);
    vColor = color;
}