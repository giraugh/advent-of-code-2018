(module
    (import "js" "mem" (memory 1))
    (import "js" "log" (func $log (param i32 i32)))
    (import "js" "logx" (func $logx (param i32)))
    (import "js" "logs" (func $logs))
    (global $PLUS i32
        (i32.const 43))
    (global $LFEED i32
        (i32.const 10))
    (global $ZERO_CHAR i32
        (i32.const 48))

    ;; Take a string slice compoes only of digits and convert it to an integer
    (func $stoi (param $off i32) (param $len i32) (result i32)
        (local $total i32)
        (local $index i32)
        (local $pow i32)

        ;; Init pow
        i32.const 1
        local.set $pow
        i32.const 0
        local.set $index
        i32.const 0
        local.set $total

        ;; Start at the end
        loop $loop
            ;; Get the byte at $index back from the end
            local.get $off
            local.get $len
            local.get $index
            i32.sub
            i32.add
            i32.const 1
            i32.sub
            i32.load8_u

            ;; Convert from char to decimal
            global.get $ZERO_CHAR
            i32.sub

            ;; Multiply by our current power
            local.get $pow
            i32.mul

            ;; Add to running
            local.get $total
            i32.add
            local.set $total

            ;; Increase power
            local.get $pow
            i32.const 10
            i32.mul
            local.set $pow

            ;; At end of len?
            local.get $index
            i32.const 1
            i32.add
            local.tee $index
            local.get $len
            i32.lt_u
            br_if $loop
        end

        local.get $total
        ;;
    )

    ;; Take a given offset into mem and scan forwards to find a LF,
    ;; returning the offset from the pos to find the LF
    (func $scanlf (param $pos i32) (result i32)
        (local $off i32)

        i32.const 0
        local.set $off
        loop $loop
            ;; Add 1 to off
            i32.const 1
            local.get $off
            i32.add
            local.tee $off

            ;; Get char at index
            local.get $pos
            i32.add
            i32.load8_u

            ;; Is it an LF?
            ;; if not, keep scanning
            global.get $LFEED
            i32.ne
            br_if $loop
        end

        ;; return the delta
        local.get $off
        ;;
    )

    ;; Scan a row of the input to get a signed value
    ;; returns the length and then the value in that order
    (func $parse_row (param $off i32) (result i32 i32)
        (local $num_s i32) ;; the sign of the current number
        (local $num_l i32) ;; the length of the current number
        (local $num_v i32)

        local.get $off

        ;; Check for a + or - to determine sign
        ;; it can only be one or the other so just check for +
        ;; Is this char a +
        i32.load8_u
        global.get $PLUS
        i32.eq
        if
            i32.const 1
            local.set $num_s
        else
            i32.const -1
            local.set $num_s
        end

        ;; Now, parse the number string as a number
        local.get $off
        i32.const 1
        i32.add ;; skip past the sign
        call $scanlf
        local.set $num_l

        ;; And parse the num value
        local.get $off
        i32.const 1
        i32.add
        local.get $num_l
        call $stoi

        ;; apply the sign
        local.get $num_s
        i32.mul
        local.set $num_v

        local.get $num_l
        local.get $num_v
        ;;
    )

    (func $list_has_val
        (param $list_off i32) (param $list_len i32) (param $val i32) (result i32)
        (local $pointer i32)
        (local $has i32)

        local.get $list_off
        local.set $pointer

        i32.const 0
        local.set $has

        loop $loop
            block $block
                local.get $pointer
                local.get $list_off
                i32.sub
                local.get $list_len
                i32.gt_u
                br_if $block

                ;; Is the item here the target item?
                local.get $pointer
                i32.load
                local.get $val
                i32.eq
                if
                    i32.const 1
                    local.set $has
                    br $block
                end

                ;; Go to next item
                local.get $pointer
                i32.const 4
                i32.add
                local.set $pointer
                br $loop
            end
        end

        local.get $has
        ;;
    )

    ;; returns new list length
    (func $append_to_list
        (param $list_off i32) (param $list_len i32) (param $val i32) (result i32)
        ;; Add to end of list
        local.get $list_off
        local.get $list_len
        i32.add
        i32.const 4
        i32.add
        local.get $val
        i32.store ;; this sig is a guess

        ;; Compute new length
        local.get $list_len
        i32.const 4 ;; because 32/8 = 4
        i32.add
        ;;
    )

    ;; Solve the AOC part for a given string slice
    (func $solve_part1 (param $off i32) (param $len i32) (result i32)
        (local $index i32) ;; char index
        (local $result i32) ;; running total

        ;; loop through each character
        i32.const 0
        local.set $index
        loop $loop
            ;; where are we at in mem?
            local.get $off
            local.get $index
            i32.add

            ;; Parse the row
            call $parse_row

            ;; And accumulate
            local.get $result
            i32.add
            local.set $result

            ;; Then skip to the next num
            local.get $index
            i32.add
            i32.const 2 ;; and the sign and the LF
            i32.add
            local.tee $index

            ;; Are we at the end of the str?
            local.get $len
            i32.lt_u
            br_if $loop
        end

        local.get $result
        ;;
    )

    ;; Solve the AOC part 2 for a given string slice
    (func $solve_part2 (param $off i32) (param $len i32) (result i32)
        (local $list_off i32)
        (local $list_len i32)

        (local $index i32) ;; char index
        (local $value i32) ;; running total

        ;; Okay we are gonna use the memory area after the input
        ;; as a list of values we've seen before
        ;; we *could* do something fancy here w/ a tree structure or a hash
        ;; but Imma try first just keep a big list and scan through it
        local.get $off
        local.get $len
        i32.add
        i32.const 1
        i32.add
        local.set $list_off
        i32.const 0
        local.set $list_len

        ;; Start the list with 0
        local.get $list_off
        local.get $list_len
        i32.const 0
        call $append_to_list
        local.set $list_len

        ;; Start looping to find repeats
        loop $loop
            block $block
                ;; where are we at in mem?
                local.get $off
                local.get $index
                i32.add

                ;; Parse the row
                call $parse_row

                ;; And accumulate
                local.get $value
                i32.add
                local.set $value

                ;; Then skip to the next num
                local.get $index
                i32.add
                i32.const 2 ;; and the sign and the LF
                i32.add
                local.get $len
                i32.rem_u
                local.set $index

                ;; Now, have we seen this value before?
                local.get $list_off
                local.get $list_len
                local.get $value
                call $list_has_val
                br_if $block

                ;; Otherwise add to the list
                local.get $list_off
                local.get $list_len
                local.get $value
                call $append_to_list
                local.set $list_len

                br $loop
            end
        end

        local.get $value
        ;;
    )

    (export "solve_part1" (func $solve_part1))
    (export "solve_part2" (func $solve_part2))
    ;;
)
