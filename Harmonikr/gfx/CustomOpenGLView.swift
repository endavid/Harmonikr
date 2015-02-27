//
//  CustomOpenGLView.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/25/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Foundation
import OpenGL.GL3
import AppKit
import GLKit

class CustomOpenGLView : NSOpenGLView {
    var triangle_vertex : [GLfloat] = [
        -1, -1,  // pos
        0, 0, 1, // color
        1, -1,
        1, 1, 0,
        1, 1,
        1, 0, 0,
        -1, 1,
        1, 1, 1
    ]
    var indices : [GLushort] = [0,1,2,3,0,2]
    
    override func awakeFromNib() {
        var attributes : [NSOpenGLPixelFormatAttribute] = [
            NSOpenGLPixelFormatAttribute(NSOpenGLPFADepthSize), NSOpenGLPixelFormatAttribute(24), NSOpenGLPixelFormatAttribute(NSOpenGLPFAOpenGLProfile), NSOpenGLPixelFormatAttribute(NSOpenGLProfileVersion3_2Core), NSOpenGLPixelFormatAttribute(0)]
        
        self.pixelFormat = NSOpenGLPixelFormat(attributes: attributes)
        
        initShaders()
    }
    override func drawRect(dirtyRect: NSRect) {
        glClearColor(0, 0, 0, 1)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        drawAnObject()
        glFlush()
    }
    
    func drawAnObject() {
        // setup
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), 0)
        glVertexAttribPointer(0, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(5 * 4), nil)
        glVertexAttribPointer(1, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(5 * 4), nil)
        // draw
        glDrawElements(GLenum(GL_TRIANGLE_STRIP), 4, GLenum(GL_UNSIGNED_SHORT), indices)
    }
    
    
    func compileShader(shaderName: NSString, shaderType: GLenum) -> GLuint {
        
        let shaderPath: NSString? = NSBundle.mainBundle().pathForResource(shaderName, ofType: nil)
        if shaderPath == nil {
            println("Can't find shader \(shaderName)")
            return 0
        }
        var error: NSError? = nil
        var glError : GLenum = 0
        let shaderString = NSString(contentsOfFile: shaderPath!, encoding: NSUTF8StringEncoding, error: &error)
        if shaderString == nil {
            println("Failed to set contents shader of shader file!")
            return 0
        }
        
        var shaderHandle: GLuint = glCreateShader(shaderType)
        glError = glGetError()
        if glError != GLenum(GL_NO_ERROR) {
            println("Failed to create shader: \(glError)")
        }
        var shaderStringUTF8 = shaderString!.cStringUsingEncoding(NSUTF8StringEncoding)
        var shaderStringLength: GLint = GLint(shaderString!.length)
        glShaderSource(shaderHandle, 1, &shaderStringUTF8, nil)
        glError = glGetError()
        if glError != GLenum(GL_NO_ERROR) {
            println("Failed to set shader source: \(glError)")
        }
        glCompileShader(shaderHandle)
        if glError != GLenum(GL_NO_ERROR) {
            println("Failed to compile shader: \(glError)")
        }
        var compileSuccess: GLint = 1 // compileSuccess never changes!!!??? 
        glGetShaderiv(shaderHandle, GLenum(GL_COMPILE_STATUS), &compileSuccess)
        if (compileSuccess == GL_FALSE) {
            println("Failed to compile shader! \(shaderName)")
            var value: GLint = 0
            glGetShaderiv(shaderHandle, GLenum(GL_INFO_LOG_LENGTH), &value)
            var infoLog: [GLchar] = [GLchar](count: Int(value), repeatedValue: 0)
            var infoLogLength: GLsizei = 0
            glGetShaderInfoLog(shaderHandle, value, &infoLogLength, &infoLog)
            var s = NSString(bytes: infoLog, length: Int(infoLogLength), encoding: NSASCIIStringEncoding)
            println(s)
            return 0
        }
        return shaderHandle
    }
    
    func initShaders() {
        
        // Compile our vertex and fragment shaders.
        var vertexShader: GLuint = self.compileShader("geometryColor.vs", shaderType: GLenum(GL_VERTEX_SHADER))
        var fragmentShader: GLuint = self.compileShader("color.fs", shaderType: GLenum(GL_FRAGMENT_SHADER))
        
        // Call glCreateProgram, glAttachShader, and glLinkProgram to link the vertex and fragment shaders into a complete program.
        var programHandle: GLuint = glCreateProgram()
        glAttachShader(programHandle, vertexShader)
        glAttachShader(programHandle, fragmentShader)
        glLinkProgram(programHandle)
        
        // Check for any errors.
        var linkSuccess: GLint = 1
        glGetProgramiv(programHandle, GLenum(GL_LINK_STATUS), &linkSuccess)
        if (linkSuccess == GL_FALSE) {
            println("Failed to create shader program!")
            var value: GLint = 0
            glGetShaderiv(programHandle, GLenum(GL_INFO_LOG_LENGTH), &value)
            var infoLog: [GLchar] = [GLchar](count: Int(value), repeatedValue: 0)
            var infoLogLength: GLsizei = 0
            glGetShaderInfoLog(programHandle, value, &infoLogLength, &infoLog)
            var s = NSString(bytes: infoLog, length: Int(infoLogLength), encoding: NSASCIIStringEncoding)
            println(s)
            return
        }
        
        // Call glUseProgram to tell OpenGL to actually use this program when given vertex info.
        glUseProgram(programHandle)
        
        // Finally, call glGetAttribLocation to get a pointer to the input values for the vertex shader, so we
        //  can set them in code. Also call glEnableVertexAttribArray to enable use of these arrays (they are disabled by default).
        //self.positionSlot = glGetAttribLocation(programHandle, "Position")
        //self.colorSlot = glGetAttribLocation(programHandle, "SourceColor")
        //glEnableVertexAttribArray(self.positionSlot)
        //glEnableVertexAttribArray(self.colorSlot)
    }
}