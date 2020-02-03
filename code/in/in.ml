let rec add n =
    if n <= 2 then (read_int ()) else
        add (n - 1) + add (n - 2) + (read_int ())
in (print_int (add 10))
