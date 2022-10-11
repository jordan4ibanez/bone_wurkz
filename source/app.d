import std.stdio;
import raylib;
import std.conv: to;

void main()
{
    // call this before using raylib
    validateRaylibBinding();
    InitWindow(1280, 720, "Bone Wurkz");
    SetTargetFPS(60);

    // Set up model
    Model model = LoadModel("assets/character.iqm");
    uint count = 0;
    ModelAnimation* animation = LoadModelAnimations("assets/character.iqm", &count);
    Texture texture = LoadTexture("assets/character.png");
    model.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = texture;

    // Align model to frame 0 of animation 0 which is called zero
    UpdateModelAnimation(model, animation[0], 0);

    // Make the camera look at the model
    Camera3D camera = Camera3D();
    camera.fovy = 70;
    camera.projection = CameraProjection.CAMERA_PERSPECTIVE;
    camera.position = Vector3(15, 10, 15);
    camera.target   = Vector3(0,  8, 0 );
    camera.up       = Vector3(0,  1, 0 );

    // Turn all the bone pointers into usable values
    uint[string] boneMap;
    for (int i = 0; i < model.boneCount; i++) {
        BoneInfo thisBone = model.bones[i];
        string boneName;
        foreach (character; thisBone.name) {
            if (character == 0) {
            break;
            }
            boneName ~= character;
        }
        boneMap[boneName] = i;
    }

    writeln(boneMap);

    // Inlined api function
    void setRotation(Vector3 newRotation, string bone) {
        Transform* animationCell = &animation.framePoses[0][boneMap[bone]];
        Quaternion goal = QuaternionFromEuler(newRotation.x, newRotation.y, newRotation.z);
        animationCell.rotation = goal;
    }
    void setPosition(Vector3 newPosition, string bone) {
        animation.framePoses[0][boneMap[bone]].translation = newPosition;
    }
    void updateAnimation() {
        UpdateModelAnimation(model, animation[0], 0);
    }

    // Animation variables
    float accumulator = 0.0;
    float increase = true;

    // Interaction with user
    bool rotation = true;
    bool position = true;
    bool head     = true;
    float speed = 0.05;
    

    while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(Colors.RAYWHITE);

        if (IsKeyPressed(KeyboardKey.KEY_R)) {
            rotation = !rotation;
        }
        if (IsKeyPressed(KeyboardKey.KEY_P)) {
            position = !position;
        }
        if (IsKeyPressed(KeyboardKey.KEY_H)) {
            head = !head;
        }

        // Begin procedural animation
        if (increase) {
            accumulator += speed;
            increase = accumulator < 1.0 ? true : false;
        } else {
            accumulator -= speed;
            increase = accumulator > -1.0 ? false : true;
        }

        // Limbs
        if (rotation) {
            setRotation(Vector3( accumulator + (DEG2RAD * 180),0,0), "Leg_Right");
            setRotation(Vector3(-accumulator + (DEG2RAD * 180),0,0), "Leg_Left" );
            setRotation(Vector3(-accumulator + (DEG2RAD * 180),0,0), "Arm_Right");
            setRotation(Vector3( accumulator + (DEG2RAD * 180),0,0), "Arm_Left" );
        }

        // Sway with torso
        if (position) {
            setPosition(Vector3( 1,6.25, accumulator / 3), "Leg_Left");
            setPosition(Vector3(-1,6.25,-accumulator / 3), "Leg_Right");
            setPosition(Vector3( 3,11.5, accumulator / 3), "Arm_Left");
            setPosition(Vector3(-3,11.5,-accumulator / 3), "Arm_Right");
        }

        // Torso
        if (rotation) {
            setRotation(Vector3(0, (DEG2RAD * 180) + (-accumulator / 10), 0), "Body");
        }

        // Head
        if (rotation && head) {
            setRotation(Vector3(0, (accumulator * (3.14 / 2.0)) + (DEG2RAD * 180), 0), "Head");
        }

        updateAnimation();
        

        BeginMode3D(camera);
        {
            DrawModel(model, Vector3(0,0,0), 1, Color(255,255,255,255));
        }
        EndMode3D();

        DrawText("This is a procedurally generated animation!", 0, 0, 28, Colors.BLACK);
        DrawText(("Press R to toggle rotation. Rotation is " ~ to!string(rotation ? "on" : "off")).ptr, 0, 30, 28, Colors.BLACK);
        DrawText(("Press P to toggle position. Position is " ~ to!string(position ? "on" : "off")).ptr, 0, 60, 28, Colors.BLACK);
        DrawText(("Press H to toggle the head. Head is " ~ to!string(head ? "on" : "off")).ptr, 0, 90, 28, Colors.BLACK);
        EndDrawing();
    }
    CloseWindow();
}
