(module
    (import "js" "mem" (memory 1))
    (import "js" "log" (func $log (param i32 i32)))
    (import "js" "logx" (func $logx (param i32)))
    (import "js" "logs" (func $logs))

    (global $LFEED i32
        (i32.const 10))
    (global $A i32
        (i32.const 97))

    (global $ALLOC_NEXT (mut i32)
        (i32.const 10))

    ;; Bump Allocator
    ;; Allocate enough room for $size bytes
    ;; TODO: grow memory size if necessary
    (func $alloc (param $size i32) (result i32)
        (local $pointer i32)

        global.get $ALLOC_NEXT
        local.tee $pointer
        local.get $size
        i32.add
        global.set $ALLOC_NEXT

        local.get $pointer
        ;;
    )

    ;; Allocate room for a Map<alphachar, u8>
    ;; returns a pointer to the map
    (func $alloc_alpha_map (result i32)
        i32.const 26 ;; 26 bytes
        call $alloc
        ;;
    )

    ;; Increase the count for a given ASCII character
    ;; UB if char is not lowercase alphabetic
    (func $add_char_to_alpha_map (param $alpha_map i32) (param $char i32)
        (local $count i32)
        (local $loc i32)

        ;; Compute address
        local.get $alpha_map
        local.get $char
        global.get $A
        i32.sub
        i32.add

        ;; Write the address for this character back into the param, we are done with it
        ;; Retrieve the value there then add one and store it again
        local.tee $loc

        ;; Load the value
        i32.load8_u
        i32.const 1
        i32.add
        local.set $count

        ;; Store it back
        local.get $loc
        local.get $count
        i32.store8

        ;;
    )

    ;; Returns (number_of_twos, number_of_threes)
    (func $check_alpha_map (param $alpha_map i32) (result i32 i32)
        (local $i i32)
        (local $v i32)
        (local $p i32)
        (local $two_count i32)
        (local $three_count i32)

        loop $m_loop
            ;; Get the value for this index
            local.get $alpha_map
            local.get $i
            i32.add
            local.tee $p
            i32.load8_u
            local.tee $v

            ;; is it two?
            i32.const 2
            i32.eq
            if
                local.get $two_count
                i32.const 1
                i32.add
                local.set $two_count
            end

            ;; is it three?
            local.get $v
            i32.const 3
            i32.eq
            if
                local.get $three_count
                i32.const 1
                i32.add
                local.set $three_count
            end

            ;; Zero out this entry so we can reuse it
            local.get $p
            i32.const 0
            i32.store8

            ;; Add 1 to i
            i32.const 1
            local.get $i
            i32.add
            local.tee $i

            ;; at the end?
            i32.const 26
            i32.lt_u
            br_if $m_loop
        end

        local.get $two_count
        local.get $three_count
        ;;
    )

    ;; Solve the AOC part for a given string slice
    (func $solve_part1 (param $off i32) (param $len i32) (result i32)
        ;; Loop through every character of the input
        (local $p i32)
        (local $c i32)
        (local $am i32)

        (local $x i32) ;; twos
        (local $y i32) ;; threes

        local.get $off
        local.set $p

        ;; Our input of length $len is alloc'd so we need to bump by that much
        local.get $len
        local.get $off
        i32.add
        i32.const 1
        i32.add
        global.set $ALLOC_NEXT

        ;; Allocate a char map for the current line
        call $alloc_alpha_map
        local.set $am

        loop $char_loop
            block $char_block
                ;; Fetch that char
                local.get $p
                i32.load8_u
                local.tee $c

                ;; Is this a newline?
                global.get $LFEED
                i32.eq
                if
                    local.get $am
                    call $check_alpha_map

                    ;; has a three?
                    i32.const 0
                    i32.gt_u
                    if
                        local.get $x
                        i32.const 1
                        i32.add
                        local.set $x
                    end

                    ;; has a two?
                    i32.const 0
                    i32.gt_u
                    if
                        local.get $y
                        i32.const 1
                        i32.add
                        local.set $y
                    end
                else
                    ;; Add this char to the map
                    local.get $am
                    local.get $c
                    call $add_char_to_alpha_map
                end

                ;; Add 1 to pointer
                local.get $p
                i32.const 1
                i32.add
                local.tee $p

                ;; At end of input?
                local.get $off
                i32.sub
                local.get $len
                i32.ge_u ;; might be gt
                br_if $char_block

                ;; And repeat...
                br $char_loop
            end
        end

        ;; Multiply x by y
        local.get $x
        local.get $y
        i32.mul
        ;;
    )

    ;; Solve the AOC part 2 for a given string slice
    (func $solve_part2 (param $off i32) (param $len i32) (result i32)
        i32.const -1
        ;;
    )

    (export "solve_part1" (func $solve_part1))
    (export "solve_part2" (func $solve_part2))
    ;;
)
