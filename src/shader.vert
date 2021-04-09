#version 450 core

uniform mat4 view;
uniform mat4 proj;

in  vec3 position;
in  vec3 colour;
out vec3 vertexColour;

void main() {
    gl_Position  = proj * view * vec4(position, 1.0);
    vertexColour = colour;
}