from jim import *


def test_vector():
    V = Vector
    assert tuple((V(1, 1, 1) + V(2, 3, 4)).xs) == (3, 4, 5)
    assert tuple((V(2, 3, 4) * 2).xs) == (4, 6, 8)
    assert tuple((2 * V(2, 3, 4)).xs) == (4, 6, 8)
    assert tuple((V(2, 4, 6) / 2).xs) == (1, 2, 3)


def test_spring():
    c1 = Circle(
        1,
        Vector(5),
        Vector(0),
        lambda body: Vector(0),
        1
    )
    c2 = Circle(
        1,
        Vector(-5),
        Vector(0),
        lambda body: Vector(0),
        2
    )
    spring = Spring(5, 1, (c1, c2))
    print(c1.a, c2.a)
    assert (c1.a - Vector(-5)).norm < 0.0000001
    assert (c2.a - Vector(2.5)).norm < 0.0000001
    c1.r = Vector(10)
    print(c1.a, c2.a)
    assert (c1.a - Vector(-10)).norm < 0.0000001
    assert (c2.a - Vector(5)).norm < 0.0000001


def test_transpose_states():
    states = [
        Body.State(Vector(1, 2), None, None, None),
        Body.State(Vector(3, 4), None, None, None),
    ]
    print(transpose_states(states))
    assert transpose_states(states) == [(1, 3), (2, 4)]
