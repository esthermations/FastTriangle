#version 450 core

in  vec3 vertexColour;
out vec4 outColour;

void main() {
    outColour = vec4(vertexColour, 1.0);
}