; TEST CODE FROM EXOMIZER

.org $2000

zp_len_lo = $a7
zp_len_hi = $a8

zp_src_lo  = $ae
zp_src_hi  = zp_src_lo + 1

zp_bits_hi = $fc

zp_bitbuf  = $fd
zp_dest_lo = zp_bitbuf + 1      ; dest addr lo
zp_dest_hi = zp_bitbuf + 2      ; dest addr hi

.MACRO mac_refill_bits
        pha
        jsr get_crunched_byte
        rol
        sta zp_bitbuf
        pla
.ENDMACRO
.MACRO mac_get_bits
.SCOPE
        adc #$80                ; needs c=0, affects v
        asl
        bpl gb_skip
gb_next:
        asl zp_bitbuf
        bne gb_ok
        mac_refill_bits
gb_ok:
        rol
        bmi gb_next
gb_skip:
        bvc skip
gb_get_hi:
        sec
        sta zp_bits_hi
        jsr get_crunched_byte
skip:
.ENDSCOPE
.ENDMACRO


.ifdef UNDEFINED_SYMBOL
	dc.b -1 ; should not be assembled
	error 1
.else
	dc.b 1 ; should be assembled
.endif

const CONSTANT = 32

.eval CONSTANT

	mac_get_bits
	mac_get_bits

get_crunched_byte:
	rts