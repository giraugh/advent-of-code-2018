(module
    (import "js" "mem" (memory 1))
    (import "js" "log" (func $log (param i32 i32)))
    (import "js" "logx" (func $logx (param i32)))
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

    ;; Solve the AOC part for a given string slice
    (func $solve (param $off i32) (param $len i32) (result i32)
        (local $index i32) ;; char index
        (local $char_p i32) ;; pointer to current char
        (local $num_l i32) ;; the length of the current number
        (local $num_s i32) ;; the sign of the current number
        (local $result i32) ;; running total

        ;; loop through each character
        i32.const 0
        local.set $index
        loop $loop
            ;; where are we at in mem?
            local.get $off
            local.get $index
            i32.add
            local.tee $char_p

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
            local.get $char_p
            i32.const 1
            i32.add ;; skip past the sign
            call $scanlf
            local.set $num_l

            ;; And parse the num value
            local.get $char_p
            i32.const 1
            i32.add
            local.get $num_l
            call $stoi

            ;; apply the sign
            local.get $num_s
            i32.mul

            ;; And accumulate
            local.get $result
            i32.add
            local.set $result

            ;; Then skip to the next num
            local.get $index
            local.get $num_l
            i32.add
            i32.const 2 ;; and the LF
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

    (export "solve" (func $solve)))
