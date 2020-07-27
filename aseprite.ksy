meta:
  id: aseprite
  endian: le
  file-extension:
    - aseprite
    - ase
seq:
  - id: header
    type: header
  - id: frames
    type: frame
    repeat: expr
    repeat-expr: header.num_frames
types:
  header:
    seq:
      - id: file_size
        type: u4
        doc: |
          File size
      - id: magic
        contents: [0xE0, 0xA5]
        doc: |
          Magic Number (0xA5E0)
      - id: num_frames
        type: u2
        doc: |
          The number of frames in the animation
      - id: width
        type: u2
        doc: |
          The width of the sprite, in pixels
      - id: height
        type: u2
        doc: |
          The height of the sprite, in pixels
      - id: pixel_format
        type: u2
        enum: pixel_format_enum
        doc: |
          The color depth of the sprite:
          - "rgba" -> 32bpp, full RGB with alpha (8bpc)
          - "grayscale" -> 16bpp, value and alpha (8bpc)
          - "indexed" -> 8bpp indexed
      - id: flags
        type: flags_bitset
        doc: |
          Various boolean flags about the ASE file
      - id: speed
        type: u2
        doc: |
          DEPRECATED!
          The speed of the animation (the number of milliseconds
          between frames).

          You should use the frame duration field from each frame
          header from now on instead of using this field.
      - type: u8
      - id: transparent_index
        type: u1
        doc: |
          Palette entry (index) which represents the transparent
          color in all non-background layers (only for
          pixel_format=indexed (8bpp) sprites).
      - type: b24
      - id: num_colors
        type: u2
        doc: |
          Number of colors (0 means 256 for old sprites).
      - id: pixel_width
        type: u1
        doc: |
          Per-pixel width (pixel ratio is pixel_width/pixel_height).
          If this or pixel_height field is zero, pixel ratio is 1:1.
      - id: pixel_height
        type: u1
        doc: |
          Per-pixel height (pixel ratio is pixel_width/pixel_height).
          If this or pixel_width field is zero, pixel ratio is 1:1.
      - id: grid_x
        type: s2
        doc: |
          The X position of the grid
      - id: grid_y
        type: s2
        doc: |
          The Y position of the grid
      - id: grid_width
        type: u2
        doc: |
          Grid width (zero if there is no grid, grid size
          is 16x16 on Aseprite by default)
      - id: grid_height
        type: u2
        doc: |
          Grid height (zero if there is no grid, grid size
          is 16x16 on Aseprite by default)
      - size: 84
    enums:
      pixel_format_enum:
        32: rgba
        16: grayscale
        8: indexed
    types:
      flags_bitset:
        seq:
          - type: b7
          - id: valid_opacity
            type: b1
            doc: Layer opacity has a valid value
          - type: b24
  frame:
    seq:
      - id: header
        type: header
      - id: chunks
        type: chunk
        repeat: expr
        repeat-expr: |
          header.num_chunks == 0 ? header.num_chunks_old : header.num_chunks
    types:
      header:
        seq:
          - id: frame_bytes
            type: u4
            doc: |
              Bytes in this frame
          - id: magic
            contents: [0xFA, 0xF1]
            doc: |
              Magic number (always 0xF1FA)
          - id: num_chunks_old
            type: u2
            doc: |
              Old field which specifies the number of "chunks"
              in this frame. If this value is 0xFFFF, we might
              have more chunks to read in this frame.
          - id: duration
            type: u2
            doc: |
              Frame duration, in milliseconds.

              If this value is 0, replace it with the `speed` value
              from the main ASE header. If you are writing this ASE
              file back out, be sure to set this field to the `speed` value
              instead of keeping it as 0, since the `speed` field
              is deprecated.
          - size: 2
          - id: num_chunks
            type: u4
            doc: |
              New field which specifies the number of "chunks"
              in this frame (if this is 0, use the num_chunks_old
              field).
      chunk:
        seq:
          - id: size
            type: u4
            doc: |
              The size, in bytes, of the chunk (including
              .size and .type fields).
          - id: type
            type: u2
            enum: chunk_type_enum
            doc: |
              The chunk type
          - id: color_profile
            type: color_profile_chunk
            if: type == chunk_type_enum::color_profile
            doc: |
              The color profile information for the sprite
          - id: palette
            type: palette_chunk
            if: type == chunk_type_enum::palette
            doc: |
              The new palette information for the sprite
              (use this palette entry over the old palette entries,
              since Aseprite will include the old versions for compatibility
              reasons).
          - id: palette_old
            type: palette_old_chunk
            if: |
              type == chunk_type_enum::palette_old_1 or type == chunk_type_enum::palette_old_2
            doc: |
              The old palette information for the sprite
              (prefer type==palette chunks, if possible)
          - id: layer
            type: layer_chunk
            if: type == chunk_type_enum::layer
            doc: |
              A single sprite layer
          - id: cel
            type: cel_chunk
            if: type == chunk_type_enum::cel
            doc: |
              A single cel layer
          - id: cel_extra
            type: cel_extra_chunk
            if: type == chunk_type_enum::cel_extra
            doc: |
              Extension information to the PREVIOUS cel
              (this chunk's index - 1)
          - id: slice
            type: slice_chunk
            if: type == chunk_type_enum::slice
            doc: |
              A single slice layer
          - id: tags
            type: tags_chunk
            if: type == chunk_type_enum::tags
            doc: |
              A single tags layer
          - id: userdata
            type: userdata_chunk
            if: type == chunk_type_enum::userdata
            doc: |
              A userdata layer adding text or color annotation information
              to the PREVIOUS layer.
          - id: mask
            type: mask_chunk
            if: type == chunk_type_enum::mask
            doc: |
              DEPRECATED: Mask information for the sprite
        enums:
          chunk_type_enum:
            0x0004: palette_old_1
            0x0011: palette_old_2
            0x2004: layer
            0x2005: cel
            0x2006: cel_extra
            0x2007: color_profile
            0x2016: mask
            0x2017: path
            0x2018: tags
            0x2019: palette
            0x2020: userdata
            0x2022: slice
        types:
          palette_chunk:
            seq:
              - id: num_entries
                type: u4
                doc: |
                  New palette size (total number of entries)
              - id: first_index
                type: u4
                doc: |
                  First color index to change
              - id: last_index
                type: u4
                doc: |
                  Last color index to change
              - size: 8
              - id: entries
                type: entry
                repeat: expr
                repeat-expr: num_entries
                doc: |
                  The palette entries
            types:
              entry:
                seq:
                  - id: flags
                    type: flag_bitset
                    doc: |
                      Entry flags
                  - id: r
                    type: u1
                    doc: |
                      Red channel (0-255)
                  - id: g
                    type: u1
                    doc: |
                      Green channel (0-255)
                  - id: b
                    type: u1
                    doc: |
                      Blue channel (0-255)
                  - id: a
                    type: u1
                    doc: |
                      Alpha channel (0-255)
                  - id: name_length
                    type: u2
                    if: flags.has_name == true
                  - id: name
                    type: str
                    size: name_length
                    encoding: utf-8
                    if: flags.has_name == true
                    doc: |
                      The name of the palette entry
                types:
                  flag_bitset:
                    seq:
                      - type: b7
                      - id: has_name
                        type: b1
                      - type: b8
          color_profile_chunk:
            seq:
              - id: type
                type: u2
                enum: type_enum
                doc: |
                  The color profile type
              - id: flags
                type: flags
              - id: fixed_gamma
                type: fixed_float
                doc: |
                  Fixed gamma (1.0 = linear)
                  Note: The gamma in sRGB is 2.2 in overall but it doesn't use
                  this fixed gamma, because sRGB uses different gamma sections
                  (linear and non-linear). If sRGB is specified with a fixed
                  gamma = 1.0, it means that this is Linear sRGB.
              - size: 8
              - id: icc_length
                type: u4
                if: type == type_enum::icc
                doc: |
                  ICC profile data length
              - id: icc_data
                size: icc_length
                if: type == type_enum::icc
                doc: |
                  ICC profile data. More info: http://www.color.org/ICC1V42.pdf
            enums:
              type_enum:
                0: none
                1: srgb
                2: embedded_icc
            types:
              flags:
                seq:
                  - type: b7
                  - id: fixed_gamma
                    type: b1
                    doc: |
                      Use special fixed gamma
                  - type: b8
              fixed_float:
                seq:
                  - id: int
                    type: u2
                    doc: |
                      The integer part of the fixed float
                  - id: dec
                    type: u2
                    doc: |
                      The decimal part of the fixed float
          palette_old_chunk:
            seq:
              - id: num_packets
                type: u2
                doc: |
                  Number of packets
              - id: packets
                type: packet
                repeat: expr
                repeat-expr: num_packets
                doc: |
                  The chunk's packets
            types:
              packet:
                seq:
                  - id: skip
                    type: u1
                    doc: |
                      The number of palette entries to skip from the last
                      packet (start from 0)
                  - id: num_colors
                    type: u1
                    doc: |
                      The number of colors in the packet (0 means 256)
                  - id: colors
                    type: color
                    repeat: expr
                    repeat-expr: |
                      num_colors == 0 ? 256 : num_colors
                    doc: |
                      The packet's colors
                types:
                  color:
                    seq:
                      - id: r
                        type: u1
                        doc: |
                          Red channel (0-255)
                      - id: g
                        type: u1
                        doc: |
                          Green channel (0-255)
                      - id: b
                        type: u1
                        doc: |
                          Blue channel (0-255)
          layer_chunk:
            seq:
              - id: flags
                type: flag_bitset
                doc: |
                  Layer flags
              - id: type
                type: u2
                enum: type_enum
                doc: |
                  Layer type
              - id: child_level
                type: u2
                doc: |
                  Layer child level

                  The child level is used to show the relationship of this
                  layer with the last one read, for example:

                      Layer name and hierarchy      Child Level
                      -----------------------------------------------
                      - Background                  0
                        `- Layer1                   1
                      - Foreground                  0
                        |- My set1                  1
                        |  `- Layer2                2
                        `- Layer3                   1
              - id: layer_width
                type: u2
                doc: |
                  IGNORED. Default layer width in pixels.
              - id: layer_height
                type: u2
                doc: |
                  IGNORED. Default layer height in pixels.
              - id: blend_mode
                type: u2
                enum: blend_mode_enum
                doc: |
                  The layer blend mode (always 0 for group layers)
              - id: opacity
                type: u1
                doc: |
                  Layer opacity (0-255)
                  NOTE: Only valid if flags.visible==true.
              - size: 3
              - id: name_size
                type: u2
              - id: name
                type: str
                size: name_size
                encoding: utf-8
                doc: |
                  Layer name
            enums:
              type_enum:
                0: image
                1: group
              blend_mode_enum:
                0: normal
                1: multiply
                2: screen
                3: overlay
                4: darken
                5: lighten
                6: color_dodge
                7: color_burn
                8: hard_light
                9: soft_light
                10: difference
                11: exclusion
                12: hue
                13: saturation
                14: color
                15: luminosity
                16: addition
                17: subtract
                18: divide
            types:
              flag_bitset:
                seq:
                  - type: b1
                  - id: reference
                    type: b1
                    doc: |
                      The layer is a reference layer
                  - id: collapsed
                    type: b1
                    doc: |
                      The layer group should be displayed collapsed
                  - id: prefer_linked
                    type: b1
                    doc: |
                      Prefer linked cels
                  - id: background
                    type: b1
                    doc: |
                      Layer is a background
                  - id: lock_movement
                    type: b1
                    doc: |
                      Lock any movement on the layer
                  - id: editable
                    type: b1
                    doc: |
                      Layer is editable
                  - id: visible
                    type: b1
                    doc: |
                      Layer is visible
                  - type: u1
          cel_chunk:
            seq:
              - id: layer_index
                type: u2
                doc: |
                  Layer index

                  The layer index is a number to identify any layer in the
                  sprite, for example:

                      Layer name and hierarchy      Layer index
                      -----------------------------------------------
                      - Background                  0
                        `- Layer1                   1
                      - Foreground                  2
                        |- My set1                  3
                        |  `- Layer2                4
                        `- Layer3                   5
              - id: x
                type: s2
                doc: |
                  X position
              - id: y
                type: s2
                doc: |
                  Y position
              - id: opacity
                type: u1
                doc: |
                  Opacity level
              - id: type
                type: u1
                enum: cel_type_enum
                doc: |
                  The format of the cel's contents
              - size: 7
              - id: raw_width
                type: u2
                if: type == cel_type_enum::raw
                doc: |
                  The cel width in pixels
              - id: raw_height
                type: u2
                if: type == cel_type_enum::raw
                doc: |
                  The cel height in pixels
              - id: pixels
                size: _parent.size - 25
                if: type == cel_type_enum::raw
                doc: |
                  The cel's pixel data

                  NOTE: This is raw byte data because Kaitai cannot accurately
                  represent the variable types here. You will need to check
                  the color_profile layer to check which format these pixels
                  will be in:

                  - rgba == 4 bytes
                  - grayscale == 2 bytes
                  - indexed = 1 byte

                  Pixels are read row by row from top to bottom,
                  for each scanline read pixels from left to right.
              - id: frame_link
                type: u2
                if: type == cel_type_enum::linked
                doc: |
                  The frame position to link with
              - size: 1 # undocumented extra byte?
                if: type == cel_type_enum::linked
              - id: width
                type: u2
                if: type == cel_type_enum::compressed
                doc: |
                  The width in pixels
              - id: height
                type: u2
                if: type == cel_type_enum::compressed
                doc: |
                  The height in pixels
              - id: pixels_compressed
                if: type == cel_type_enum::compressed
                size: _parent.size - 25
                # NOTE: Uncomment if you have zlib available
                #       and you'd like to have Kaitai do automatic
                #       inflation for you.
                #process: zlib
                doc: |
                  The raw pixel data (inflated if `process: zlib` was uncommented
                  in the Kaitai definition file prior to creating the parser).

                  NOTE: This is raw byte data because Kaitai cannot accurately
                  represent the variable types here. You will need to check
                  the color_profile layer to check which format these pixels
                  will be in:

                  - rgba == 4 bytes
                  - grayscale == 2 bytes
                  - indexed = 1 byte

                  Pixels are read row by row from top to bottom,
                  for each scanline read pixels from left to right.
            enums:
              cel_type_enum:
                0: raw
                1: linked
                2: compressed
          cel_extra_chunk:
            seq:
              - id: flags
                type: flags_bitset
                doc: |
                  Flags (set to zero)
              - id: precise_x
                type: fixed
                doc: |
                  Precise X position
              - id: precise_y
                type: fixed
                doc: |
                  Precise Y position
              - id: width
                type: fixed
                doc: |
                  Width of the cel in the sprite (scaled in real-time)
              - id: height
                type: fixed
                doc: |
                  Height of the cel in the sprite (scaled in real-time)
              - size: 16
            types:
              flags_bitset:
                seq:
                  - type: b7
                  - id: precise_bounds
                    type: b1
                    doc: |
                      Precise bounds are set
              fixed:
                seq:
                  - id: int
                    type: u2
                    doc: |
                      The integer part of the fixed float
                  - id: dec
                    type: u2
                    doc: |
                      The decimal part of the fixed float
          slice_chunk:
            seq:
              - id: num_keys
                type: u4
                doc: |
                  Number of "slice keys"
              - id: flags
                type: flags_bitset
                doc: |
                  Slice flags
              - type: u4
              - id: name_size
                type: u2
              - id: name
                type: str
                size: name_size
                encoding: utf-8
                doc: |
                  The slice's name
              - id: keys
                type: key
                repeat: expr
                repeat-expr: num_keys
                doc: |
                  The slice's list of keys
            types:
              flags_bitset:
                seq:
                  - type: b6
                  - id: has_pivot
                    type: b1
                    doc: |
                      Has pivot information
                  - id: patch9
                    type: b1
                    doc: |
                      It's a 9-patches slice
              key:
                seq:
                  - id: frame_no
                    type: u4
                    doc: |
                      Frame number (this slice is valid from thie frame to
                      the end of the animation)
                  - id: x
                    type: s4
                    doc: |
                      Slice X origin coordinate in the sprite
                  - id: y
                    type: s4
                    doc: |
                      Slice Y origin coordinate in the sprite
                  - id: width
                    type: u4
                    doc: |
                      Slice width (can be 0 if this slice is hidden
                      in the animation from the given frame)
                  - id: height
                    type: u4
                    doc: |
                      Slice height (can be 0 if this slice is hidden
                      in the animation from the given frame)
                  - id: center_x
                    type: s4
                    if: _parent.flags.patch9 == true
                    doc: |
                      Center X position (relative to slice bounds)
                  - id: center_y
                    type: s4
                    if: _parent.flags.patch9 == true
                    doc: |
                      Center Y position (relative to slice bounds)
                  - id: center_width
                    type: u4
                    if: _parent.flags.patch9 == true
                    doc: |
                      Center width
                  - id: center_height
                    type: u4
                    if: _parent.flags.patch9 == true
                    doc: |
                      Center height
                  - id: pivot_x
                    type: s4
                    if: _parent.flags.has_pivot == true
                    doc: |
                      Pivot X position (relative to the slice origin)
                  - id: pivot_y
                    type: s4
                    if: _parent.flags.has_pivot == true
                    doc: |
                      Pivot y position (relative to the slice origin)
          tags_chunk:
            seq:
              - id: num_tags
                type: u2
                doc: |
                  The number of tags
              - size: 8
              - id: tags
                type: tag
                repeat: expr
                repeat-expr: num_tags
                doc: |
                  The sprite's list of tags
            types:
              tag:
                seq:
                  - id: from
                    type: u2
                    doc: |
                      From frame
                  - id: to
                    type: u2
                    doc: |
                      To frame
                  - id: direction
                    type: u1
                    enum: direction_enum
                    doc: |
                      Loop animation direction
                  - size: 8
                  - id: color
                    type: color
                    doc: |
                      The tag's color
                  - type: u1
                  - id: name_size
                    type: u2
                  - id: name
                    type: str
                    size: name_size
                    encoding: utf-8
                    doc: |
                      The tag's name
                enums:
                  direction_enum:
                    0: forward
                    1: reverse
                    2: ping_pong
                types:
                  color:
                    seq:
                      - id: r
                        type: u1
                        doc: |
                          The red channel (0-255)
                      - id: g
                        type: u1
                        doc: |
                          The green channel (0-255)
                      - id: b
                        type: u1
                        doc: |
                          The blue channel (0-255)
          userdata_chunk:
            seq:
              - id: flags
                type: flags_bitset
                doc: |
                  Flags for the userdata
              - id: text_size
                type: u2
                if: flags.has_text == true
              - id: text
                type: str
                size: text_size
                encoding: utf-8
                if: flags.has_text == true
                doc: |
                  Userdata text
              - id: r
                type: u1
                if: flags.has_color == true
                doc: |
                  The red channel (0-255)
              - id: g
                type: u1
                if: flags.has_color == true
                doc: |
                  The green channel (0-255)
              - id: b
                type: u1
                if: flags.has_color == true
                doc: |
                  The blue channel (0-255)
              - id: a
                type: u1
                if: flags.has_color == true
                doc: |
                  The alpha channel (0-255)
            types:
              flags_bitset:
                seq:
                  - type: b6
                  - id: has_color
                    type: b1
                    doc: |
                      Userdata has color information
                  - id: has_text
                    type: b1
                    doc: |
                      Userdata has textual information
                  - type: b24
          mask_chunk:
            seq:
              - id: x
                type: s2
                doc: |
                  X position
              - id: y
                type: s2
                doc: |
                  Y position
              - id: width
                type: u2
                doc: |
                  Mask width
              - id: height
                type: u2
                doc: |
                  Mask height
              - size: 8
              - id: name_size
                type: u2
              - id: name
                type: str
                size: name_size
                encoding: utf-8
                doc: |
                  Mask name
              - id: bitmap
                size: |
                  height * ( ( width + 7 ) / 8 )
                doc: |
                  Each byte contains 8 pixels (the leftmost pixels
                  are packed into the high order bits)
