let rec f n =
    if n = 0 then 0 else f (n - 1) + (n * 4)
in print_int (f 30)
