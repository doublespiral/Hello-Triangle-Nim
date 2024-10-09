import staticglfw as glfw
import opengl


type 
    Successful = bool
    ShaderSource = string 
    GlId = GLuint

type Application = ref object 
    window: Window


const 
    screen_width* = 640
    screen_height* = 480
    title* = "Nim Triangle"


proc shouldClose*(window: Window): bool {.inline.} =
    return bool( window.windowShouldClose() )

proc initalize*(app: Application): Successful =
    if glfw.init().bool == false:
        return false

    glfw.windowHint(CONTEXT_VERSION_MAJOR, 3)
    glfw.windowHint(CONTEXT_VERSION_MINOR, 3)
    glfw.windowHint(OPENGL_FORWARD_COMPAT, true.cint)
    glfw.windowHint(OPENGL_PROFILE, OPENGL_COMPAT_PROFILE)


    app.window = createWindow(
        screen_width, screen_height, 
        title, nil, nil
    )

    if (app.window == nil):
        return false

    app.window.makeContextCurrent()
    #glfw.swapInterval(1)

    opengl.loadExtensions()

    echo cast[cstring]( glGetString(GL_VERSION) )
    echo cast[cstring]( glGetString(GL_RENDERER) )

    return true


proc exit*(app: Application): void =
    app.window.destroyWindow()
    glfw.terminate()
    quit(0)


let
    vertex_shader = """
#version 330 core

layout (location = 0) in vec4 position;

void main() {
    gl_Position = position;
}
    """

    fragment_shader = """
#version 330 core

layout (location = 0) out vec4 color;

void main() {
    color = vec4(1.0, 1.0, 1.0, 1.0);
}
    """

proc compileShader(shader_type: GLenum, source: ShaderSource): GlId =
    result = glCreateShader(shader_type)

    let c_source = cstring(source)
    let c_source_ptr = cast[cstringArray](c_source.addr)

    glShaderSource(result, 1, c_source_ptr, nil)
    glCompileShader(result)

    var did_compile: GLint # treating it as a bool here
    glGetShaderiv(result, GL_COMPILE_STATUS, did_compile.addr)

    if did_compile.bool:
        debugEcho "shader compiled"
        return result

    var shader_length: GLint
    glGetShaderiv(result, GL_INFO_LOG_LENGTH, shader_length.addr)
    var message: cstring 
    glGetShaderInfoLog(result, shader_length, shader_length.addr, message)
            
    let shader_type_text = if shader_type == GL_VERTEX_SHADER:
        "vertext"
    else:
        "fragment"

    echo "ERROR: Failed to compile `", shader_type_text, " shader!"
    echo message
    glDeleteShader(result)

    return 0


proc createShader(vertex, fragment: ShaderSource): GlId =
    result = glCreateProgram()
    let vertex_id = compileShader(GL_VERTEX_SHADER, vertex)
    let fragment_id = compileShader(GL_FRAGMENT_SHADER, fragment)

    glAttachShader(result, vertex_id)
    glAttachShader(result, fragment_id)
    glLinkProgram(result)
    glValidateProgram(result)

    glDeleteShader(vertex_id)
    glDeleteShader(fragment_id)

    return result


proc main(): void =
    let app = Application(window: nil)
    defer: app.exit()

    if not app.initalize():
        app.exit()
    
    glViewport(0, 0, screen_width, screen_height)
    glClearColor(0, 0, 0, 1)

    # make triangle #
    var positions: array[6, float32] = [
        -0.5, -0.5,
         0.0,  0.5,
         0.5, -0.5,
    ]

    var vao: uint32
    glGenVertexArrays(1, vao.addr)
    glBindVertexArray(vao)

    var buffer: GlId
    glGenBuffers(1, buffer.addr)
    glBindBuffer(GL_ARRAY_BUFFER, buffer)
    

    glBufferData(
        GL_ARRAY_BUFFER, ( sizeof(float32)*6 ), 
        positions[0].addr, GL_STATIC_DRAW
    )

    # enable our vertex array 
    glEnableVertexAttribArray(0)
    glVertexAttribPointer(
        0, 2, # in this case, we're in 2d so this triangle only has 2 points per vertex
        cGL_FLOAT, 
        false, # already normalized
        sizeof(float32) * 2, # our vertex buffer only has position data atm (offset to get to the next vertex)
        cast[pointer](0)
    )
    # finished making triangle #

    let shader: GlId = createShader(vertex_shader, fragment_shader)
    glUseProgram(shader)
    
    defer: glDeleteProgram(shader)


    while not app.window.shouldClose():
        glClear(GL_COLOR_BUFFER_BIT)

        glDrawArrays(GL_TRIANGLES, 0, 3)

        app.window.swapBuffers()
        pollEvents()


    return

when is_main_module: main()