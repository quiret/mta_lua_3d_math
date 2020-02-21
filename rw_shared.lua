-- RenderWare stream parsing implementations by (c)The_GTA.
-- Since Lua cannot process data as efficiently as native languages, the implementations
-- in this file are optimized for comfort instead of performance.
-- We do not implement reading "broken RW files" with their chunk sizes borked; fix them with
-- public tools before loading them.

local function _read_byte(filePtr)
    local numbytes = fileRead(filePtr, 1);
    
    if not (numbytes) or (#numbytes < 1) then
        return false;
    end
    
    return string.byte(numbytes, 1);
end

local function _read_uint16(filePtr)
    local numbytes = fileRead(filePtr, 2);
    
    if not (numbytes) or (#numbytes < 2) then
        return false;
    end
    
    return ( string.byte(numbytes, 2) * 0x0100 + string.byte(numbytes, 1) );
end

local function _read_uint32(filePtr)
    local numbytes = fileRead(filePtr, 4);
    
    if not (numbytes) or (#numbytes < 4) then
        return false;
    end
    
    return ( string.byte(numbytes, 4) * 0x01000000 + string.byte(numbytes, 3) * 0x00010000 + string.byte(numbytes, 2) * 0x00000100 + string.byte(numbytes, 1) );
end

local function _read_float32(filePtr)
    local bytes = fileRead(filePtr, 4);
    
    if not (bytes) or (#bytes < 4) then return false; end;
    
    -- Vendor function.
    return bytes2float(bytes);
end

local function _read_rwversion(filePtr)
    local verBytes = fileRead(filePtr, 4);
    
    if not (verBytes) or (#verBytes < 4) then return false; end;
    
    local vb1 = string.byte(verBytes, 1);
    local vb2 = string.byte(verBytes, 2);
    local vb3 = string.byte(verBytes, 3);
    local vb4 = string.byte(verBytes, 4);
    
    local rwLibMajor = bitExtract(vb4, 6, 2);
    local rwRelMajor = bitExtract(vb4, 2, 4);
    local rwRelMinor = bitExtract(vb4, 0, 2) * 0x0F + bitExtract(vb3, 6, 2);
    local rwBinFmtRev = bitExtract(vb3, 0, 6);
    
    local buildNumber = ( vb2 * 0x0100 + vb1 );
    
    local verInfo = {};
    verInfo.libMajor = rwLibMajor + 3;
    verInfo.relMajor = rwRelMajor;
    verInfo.relMinor = rwRelMinor;
    verInfo.binFmtRev = rwBinFmtRev;
    verInfo.buildNumber = buildNumber;
    
    return verInfo;
end

local function rwReadChunkHeader(filePtr)
    local chunkType = _read_uint32(filePtr);
    local chunkSize = _read_uint32(filePtr);
    local chunkVersion = _read_rwversion(filePtr);
    
    if not (chunkType) or not (chunkSize) or not (chunkVersion) then return false; end;
    
    local chunk = {};
    chunk.type = chunkType;
    chunk.version = chunkVersion;
    chunk.size = chunkSize;
    
    return chunk;
end

local function readPackedVector(filePtr)
    local vec = {};
    
    vec.x = _read_float32(filePtr);
    vec.y = _read_float32(filePtr);
    vec.z = _read_float32(filePtr);
    
    return vec;
end

local function readPackedMatrix(filePtr)
    local matrix = {};

    matrix.right = readPackedVector(filePtr);
    matrix.up = readPackedVector(filePtr);
    matrix.front = readPackedVector(filePtr);
    
    if not (matrix.right) or not (matrix.up) or not (matrix.front) then return false; end;
    
    return matrix;
end

local function readExtensions(filePtr)
    local chunkHeader = rwReadChunkHeader(filePtr);
    
    if not (chunkHeader) then
        return false, "failed to read chunk header";
    end
    
    if not (chunkHeader.type == 0x03) then
        return false, "not an extension (got " .. chunkHeader.type .. ")";
    end
    
    -- We just skip extensions, for now.
    local curSeek = fileGetPos(filePtr);
    
    fileSetPos(filePtr, curSeek + chunkHeader.size );
    
    return {};
end

function rwCreateFrame()
    local frame = {};
    
    return frame;
end

local function readFrameList(filePtr)
    local chunkHeader = rwReadChunkHeader(filePtr);
    
    if not (chunkHeader) then
        return false, "failed to read chunk header";
    end
    
    if not (chunkHeader.type == 0xE) then
        return false, "not a frame list";
    end
    
    local structHeader = rwReadChunkHeader(filePtr);
    
    if not (structHeader) then
        return false, "failed to read struct chunk header";
    end
    
    if not (structHeader.type == 1) then
        return false, "not a struct chunk";
    end
    
    local num_frames = _read_uint32(filePtr);
    
    if not (num_frames) then
        return false, "failed to read number of frames";
    end
    
    local frames = {};
    
    for iter=1,num_frames,1 do
        local rotation_mat = readPackedMatrix(filePtr);
        
        if not (rotation_mat) then
            return false, "failed to read rotation matrix";
        end
        
        local translation = readPackedVector(filePtr);
        
        if not (translation) then
            return false, "failed to read translation offset";
        end
        
        local frame_idx = _read_uint32(filePtr);
        
        if not (frame_idx) then
            return false, "failed to read frame index";
        end
        
        local matrix_flags = _read_uint32(filePtr);
        
        if not (matrix_flags) then
            return false, "failed to read matrix flags";
        end
        
        local frame = rwCreateFrame();
        frame.rotation_mat = rotation_mat;
        frame.idx = frame_idx;
        frame.translation = translation;
        frame.mat_flags = matrix_flags;
        
        frames[iter] = frame;
    end
    
    for n=1,num_frames,1 do
        local extensions, err = readExtensions(filePtr);
        
        if not (extensions) then
            return false, "failed to read extensions: " .. err;
        end
        
        frames[n].extensions = extensions;
    end
    
    local framelist = {};
    framelist.frames = frames;

    return framelist;
end

local function readBoundingSphere(filePtr)
    local sphere = {};
    sphere.x = _read_float32(filePtr);
    sphere.y = _read_float32(filePtr);
    sphere.z = _read_float32(filePtr);
    sphere.r = _read_float32(filePtr);
    
    if not (sphere.x) or not (sphere.y) or not (sphere.z) or not (sphere.r) then
        return false;
    end
    
    return sphere;
end

local function readStringChunk(filePtr)
    local chunkHeader = rwReadChunkHeader(filePtr);
    
    if not (chunkHeader) then
        return false, "failed to read chunk header";
    end
    
    if not (chunkHeader.type == 0x02) then
        return false, "not a string";
    end
    
    local data = fileRead(filePtr, chunkHeader.size);
    
    if not (data) then
        return false, "failed to read string character bytes";
    end
    
    -- Remove trailing bytes of zeroes.
    local non_zero_cnt = string.find(data, "\0");
    
    if (non_zero_cnt) then
        return string.sub(data, 1, non_zero_cnt);
    end
    
    return data;
end

function rwReadTextureInfo(filePtr)
    local chunkHeader = rwReadChunkHeader(filePtr);
    
    if not (chunkHeader) then
        return false, "failed to read chunk header";
    end
    
    if not (chunkHeader.type == 0x06) then
        return false, "not a texture info";
    end
    
    local structHeader = rwReadChunkHeader(filePtr);
    
    if not (structHeader) then
        return false, "failed to read struct chunk header";
    end
    
    if not (structHeader.type == 1) then
        return false, "not a struct chunk";
    end
    
    local tex_flags = _read_uint32(filePtr);
    
    if not (tex_flags) then
        return false, "failed to read texture info flags";
    end
    
    local filterMode = bitExtract(tex_flags, 0, 8);
    local uAddr = bitExtract(tex_flags, 8, 4);
    local vAddr = bitExtract(tex_flags, 12, 4);
    local hasMips = bitExtract(tex_flags, 16, 1);
    
    local texName = readStringChunk(filePtr);
    
    if not (texName) then
        return false, "failed to read texture name";
    end
    
    local maskName = readStringChunk(filePtr);
    
    if not (maskName) then
        return false, "failed to read mask name";
    end
    
    local extension = readExtensions(filePtr);
    
    if not (extension) then
        return false, "failed to read extensions";
    end
    
    local textureInfo = {};
    textureInfo.filterMode = filterMode;
    textureInfo.uAddr = uAddr;
    textureInfo.vAddr = vAddr;
    textureInfo.hasMips = hasMips;
    textureInfo.texName = texName;
    textureInfo.maskName = maskName;
    textureInfo.extension = extension;
    
    return textureInfo;
end

function rwReadMaterial(filePtr)
    local chunkHeader = rwReadChunkHeader(filePtr);
    
    if not (chunkHeader) then
        return false, "failed to read chunk header";
    end
    
    if not (chunkHeader.type == 0x07) then
        return false, "not a material";
    end
    
    local structHeader = rwReadChunkHeader(filePtr);
    
    if not (structHeader) then
        return false, "failed to read struct chunk header";
    end
    
    if not (structHeader.type == 1) then
        return false, "not a struct chunk";
    end
    
    local mat_flags = _read_uint32(filePtr);
    local red = _read_byte(filePtr);
    local green = _read_byte(filePtr);
    local blue = _read_byte(filePtr);
    local alpha = _read_byte(filePtr);
    local pad0 = _read_uint32(filePtr);
    local int_isTextured = _read_uint32(filePtr);
    local ambient = _read_float32(filePtr);
    local specular = _read_float32(filePtr);
    local diffuse = _read_float32(filePtr);
    
    if not (mat_flags) or not (red) or not (green) or not (blue) or not (alpha) or
       not (pad0) or not (int_isTextured) or not (ambient) or not (specular) or
       not (diffuse) then
       
       return false, "failed to read struct data";
    end

    local isTextured = not (int_isTextured == 0);
    
    local texture = false;
    
    if (isTextured) then
        local err;
        texture, err = rwReadTextureInfo(filePtr);
        
        if not (texture) then
            return false, "failed to read texture: " .. err;
        end
    end
    
    local extension, err = readExtensions(filePtr);
    
    if not (extension) then
        return false, "failed to read extensions: " .. err;
    end
    
    local material = {};
    material.flags = mat_flags;
    material.red = red;
    material.green = green;
    material.blue = blue;
    material.alpha = alpha;
    material.texture = texture;
    material.ambient = ambient;
    material.specular = specular;
    material.diffuse = diffuse;
    material.extension = extension;
    
    return material;
end

local function readMaterialList(filePtr)
    local chunkHeader = rwReadChunkHeader(filePtr);
    
    if not (chunkHeader) then
        return false, "failed to read chunk header";
    end
    
    if not (chunkHeader.type == 0x08) then
        return false, "not a material list";
    end
    
    local structHeader = rwReadChunkHeader(filePtr);
    
    if not (structHeader) then
        return false, "failed to read struct header";
    end
    
    if not (structHeader.type == 1) then
        return false, "not a struct header";
    end
    
    local num_materials = _read_uint32(filePtr);
    
    if not (num_materials) then
        return false, "failed to read number of materials";
    end
    
    local mat_indices = {};
    
    for iter=1,num_materials,1 do
        local mat_idx = _read_uint32(filePtr);
        
        if not (mat_idx) then
            return false, "failed to read material index";
        end
        
        mat_indices[iter] = mat_idx;
    end
    
    local materials = {};
    
    for iter=1,num_materials,1 do
        local mat, err = rwReadMaterial(filePtr);
        
        if not (mat) then
            return false, "failed to read material #" .. iter ..": " .. err;
        end
        
        materials[iter] = mat;
    end
    
    local materialList = {};
    materialList.list = materials;
    materialList.indices = mat_indices;
    
    return materialList;
end

local function rwReadGeometry(filePtr)
    local chunkHeader = rwReadChunkHeader(filePtr);
    
    if not (chunkHeader) then
        return false, "failed to read chunk header";
    end
    
    if not (chunkHeader.type == 0x0F) then
        return false, "not a geometry";
    end
    
    local structHeader = rwReadChunkHeader(filePtr);
    
    if not (structHeader) then
        return false, "failed to read struct chunk header";
    end
    
    if not (structHeader.type == 1) then
        return false, "not a struct chunk";
    end 
    
    local formatFlags = _read_uint32(filePtr);
    local numTriangles = _read_uint32(filePtr);
    local numVertices = _read_uint32(filePtr);
    local numMorphTargets = _read_uint32(filePtr);
    
    if not (formatFlags) then
        return false, "failed to read format flags";
    end
    
    if not (numTriangles) then
        return false, "failed to read num triangles";
    end
    
    if not (numVertices) then
        return false, "failed to read num vertices";
    end
    
    if not (numMorphTargets) then
        return false, "failed to read num morph targets";
    end
    
    -- What do we actually have?
    local is_tri_strip = bitTest(formatFlags, 0x00000001);
    local has_vertex_pos = bitTest(formatFlags, 0x00000002);
    local has_vertex_texcoord = bitTest(formatFlags, 0x00000004);
    local has_vertex_colors = bitTest(formatFlags, 0x00000008);
    local has_vertex_normals = bitTest(formatFlags, 0x00000010);
    local has_geom_lighting = bitTest(formatFlags, 0x00000020);
    local has_geom_mat_modulation = bitTest(formatFlags, 0x00000040);
    local has_geom_texcoord_2 = bitTest(formatFlags, 0x00000080);
    local is_geom_native = bitTest(formatFlags, 0x01000000);
    
    -- We ignore the flag bits that we do not care about
    -- This should not happen in clean implementations.
    
    -- I guess geometry can be missing from the container BUT DOES NOT HAVE TO.
    
    if (is_geom_native) then
        return false, "fatal: native geometry not supported";
    end
    
    local arbitrary_numTexSets = bitExtract(formatFlags, 16, 8);
    
    local numTexSets = 0;
    
    if (arbitrary_numTexSets > 0) then
        numTexSets = arbitrary_numTexSets;
    else
        if (has_geom_texcoord) then
            numTexSets = 1;
        elseif (has_geom_texcoord_2) then
            numTexSets = 2;
        end
    end
    
    local commondata_vertices = {};
    
    for iter=1,numVertices,1 do
        local vert = {};
        vert.red = 0;
        vert.green = 0;
        vert.blue = 0;
        vert.alpha = 0;
        vert.texcoords = {};
        commondata_vertices[iter] = vert;
    end
    
    if (has_vertex_colors) then
        for iter=1,numVertices,1 do
            local vert = commondata_vertices[iter];
            vert.red = _read_float32(filePtr);
            vert.green = _read_float32(filePtr);
            vert.blue =  _read_float32(filePtr);
            vert.alpha = _read_float32(filePtr);
            
            if not (vert.red) or not (vert.green) or not (vert.blue) or not (vert.alpha) then
                return false, "failed to read vertex color";
            end
        end
    end
    
    for tsetn=1,numTexSets,1 do
        for iter=1,numVertices,1 do
            local vert = commondata_vertices[iter];
            
            local texcoord = {};
            texcoord.u = _read_float32(filePtr);
            texcoord.v = _read_float32(filePtr);
            
            if not (texcoord.u) or not (texcoord.v) then
                return false, "failed to read vertex texture coordinate #" .. tsetn;
            end
            
            vert.texcoords[tsetn] = texcoord;
        end
    end
    
    local triangles = {};
    
    for iter=1,numTriangles,1 do
        local tri = {};
        tri.vertex2 = _read_uint16(filePtr);
        tri.vertex1 = _read_uint16(filePtr);
        tri.mat_id = _read_uint16(filePtr);
        tri.vertex3 = _read_uint16(filePtr);
        
        if not (tri.vertex2) or not (tri.vertex1) or not (tri.mat_id) or not (tri.vertex3) then
            return false, "failed to read triangle";
        end
        
        triangles[iter] = tri;
    end
    
    local morphTargets = {};
    
    for mtiter=1,numMorphTargets,1 do
        local mtarget = {};
        mtarget.sphere = readBoundingSphere(filePtr);
        local int_hasVertices = _read_uint32(filePtr);
        local int_hasNormals = _read_uint32(filePtr);
        
        if not (mtarget.sphere) or not (int_hasVertices) or not (int_hasNormals) then
            return false, "failed to read morph target #" .. mtiter;
        end
        
        local vertices = false;
        
        local hasVertices = not (int_hasVertices == 0);
        local hasNormals = not (int_hasNormals == 0);
        
        if (hasVertices) or (hasNormals) then
            vertices = {};
            
            for iter=1,numVertices,1 do
                local vert = {};
                vert.x = 0;
                vert.y = 0;
                vert.z = 0;
                vert.nx = 0;
                vert.ny = 0;
                vert.nz = 0;
                vertices[iter] = vert;
            end
        end
        
        if (hasVertices) then
            for iter=1,numVertices,1 do
                local vert = vertices[iter];
                vert.x = _read_float32(filePtr);
                vert.y = _read_float32(filePtr);
                vert.z = _read_float32(filePtr);
                
                if not (vert.x) or not (vert.y) or not (vert.z) then
                    return false, "failed to read morph target vertex translation";
                end
            end
        end
        
        if (hasNormals) then
            for iter=1,numVertices,1 do
                local vert = vertices[iter];
                vert.nx = _read_float32(filePtr);
                vert.ny = _read_float32(filePtr);
                vert.nz = _read_float32(filePtr);
                
                if not (vert.nx) or not (vert.ny) or not (vert.nz) then
                    return false, "failed to read morph target vertex normal";
                end
            end
        end
        
        mtarget.vertices = vertices;
        
        morphTargets[mtiter] = mtarget;
    end
    
    local materials, err = readMaterialList(filePtr);
    
    if not (materials) then
        return false, "failed to read material list: " .. err;
    end
    
    local extension, err = readExtensions(filePtr);
    
    if not (extension) then
        return false, "failed to read extensions: " .. err;
    end
    
    local geom = {};
    geom.common_vertData = commondata_vertices;
    geom.triangles = triangles;
    geom.morphTargets = morphTargets;
    geom.hasDynamicLighting = has_geom_lighting;
    geom.hasMaterialModulation = has_geom_mat_modulation;
    geom.hasNativeData = is_geom_native;
    geom.materialList = materials;
    geom.extension = extension;
    
    return geom;
end

local function readGeometryList(filePtr)
    local chunkHeader = rwReadChunkHeader(filePtr);
    
    if not (chunkHeader) then
        return false, "failed to read chunk header";
    end
    
    if not (chunkHeader.type == 0x1A) then
        return false, "not a geometry list";
    end
    
    local structHeader = rwReadChunkHeader(filePtr);
    
    if not (structHeader) then
        return false, "failed to read struct chunk";
    end
    
    if not (structHeader.type == 1) then
        return false, "not a struct chunk";
    end
    
    local num_geoms = _read_uint32(filePtr);
    
    if not (num_geoms) then
        return false, "failed to read number of geometries";
    end
    
    local geometries = {};
    
    for iter=1,num_geoms,1 do
        local geom, err = rwReadGeometry(filePtr);
        
        if not (geom) then
            return false, "failed to read geometry #" .. iter .. ": " .. err;
        end
        
        geometries[iter] = geom;
    end
    
    return geometries;
end

function rwReadAtomic(filePtr)
    local chunkHeader = rwReadChunkHeader(filePtr);
    
    if not (chunkHeader) then
        return false, "failed to read chunk header";
    end
    
    if not (chunkHeader.type == 0x14) then
        return false, "not an atomic";
    end
    
    local structHeader = rwReadChunkHeader(filePtr);
    
    if not (structHeader) then
        return false, "failed to read struct chunk header";
    end
    
    if not (structHeader.type == 1) then
        return false, "not a struct chunk";
    end
    
    local frameIndex = _read_uint32(filePtr);
    local geomIndex = _read_uint32(filePtr);
    local flags = _read_uint32(filePtr);
    local unused = _read_uint32(filePtr);
    
    if not (frameIndex) or not (geomIndex) or not (flags) or not (unused) then
        return false, "failed to read struct members";
    end
    
    local doCollisionTest = bitTest(flags, 0x01);
    local doRender = bitTest(flags, 0x04);
    
    local extension, err = readExtensions(filePtr);
    
    if not (extension) then
        return false, "failed to read extension: " .. err;
    end
    
    local atomic = {};
    atomic.frameIndex = frameIndex;
    atomic.geomIndex = geomIndex;
    atomic.doCollisionText = doCollisionTest;
    atomic.doRender = doRender;
    atomic.extension = extension;
    
    return atomic;
end

function rwReadClump(filePtr)
    local mainChunkHeader = rwReadChunkHeader(filePtr);
    
    if not (mainChunkHeader) then
        fileClose(filePtr);
        return false, "failed to read DFF chunk header";
    end
    
    if not (mainChunkHeader.version.libMajor == 3) or not (mainChunkHeader.version.relMajor >= 5) then
        return false, "only San Andreas files are supported (got "
        .. mainChunkHeader.version.libMajor .. "." .. mainChunkHeader.version.relMajor .. ")";
    end
    
    if not (mainChunkHeader.type == 0x10) then 
        return false, "not a DFF file (ID: " .. mainChunkHeader.type .. ")";
    end
    
    -- Process clump stuff.
    local clumpMetaHeader = rwReadChunkHeader(filePtr);
    
    if not (clumpMetaHeader) then
        return false, "failed to read clump meta header";
    end
    
    local num_atomics = _read_uint32(filePtr);
    local num_lights = _read_uint32(filePtr);
    local num_cameras = _read_uint32(filePtr);
    
    if not (num_atomics) then
        return false, "failed to read number of atomics";
    end
    
    if not (num_lights) then
        return false, "failed to read number of lights";
    end
    
    if not (num_cameras) then
        return false, "failed to read number of cameras";
    end
    
    if (num_lights > 0) then
        return false, "fatal: lights are not supported";
    end
    
    if (num_cameras > 0) then
        return false, "fatal: cameras are not supported";
    end
    
    local framelist, err = readFrameList(filePtr);
    
    if not (framelist) then
        return false, "failed to read framelist: " .. err;
    end
    
    local geomlist, err = readGeometryList(filePtr);
    
    if not (geomlist) then
        return false, "failed to read geometrylist: " .. err;
    end
    
    local atomics = {};
    
    for iter=1,num_atomics,1 do
        local atomic, err = rwReadAtomic(filePtr);
        
        if not (atomic) then
            return false, "failed to read atomic: " .. err;
        end
        
        atomics[iter] = atomic;
    end

    local extension, err = readExtensions(filePtr);
    
    if not (extension) then
        return false, "failed to read extension: " .. err;
    end
    
    -- TODO: link up geometries with atomics and their frames.
    
    local dff = {};
    dff.framelist = framelist;
    dff.geomlist = geomlist;
    dff.atomics = atomics;
    
    return dff;
end