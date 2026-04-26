# Minimales SageMath Testprogramm (test_sage.py)


def sage_test():
    # Symbolische Variable definieren
    x = var('x')
    
    # Funktion definieren
    f = sin(x^2)
    
    # Berechnung: Ableitung
    derivative_f = diff(f, x)
    print(f"Funktion: {f}")
    print(f"Ableitung: {derivative_f}")
    
    # Berechnung: Integral
    integral_f = integral(f, x)
    print(f"Integral: {integral_f}")
    
    # Beispiel für ein Plot (erfordert matplotlib)
    # P = plot(f, (x, -2, 2))
    # P.show()

if __name__ == "__main__":
    sage_test()
