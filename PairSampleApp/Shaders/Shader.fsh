//
//  Shader.fsh
//  Game
//
//  Created by Matt Loflin on 1/19/17.
//  Copyright © 2017 Pair, Inc. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
