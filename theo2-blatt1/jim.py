
# coding: utf-8

# Originally converted from an IPython Notebook, hence the code is
# a little bit unusual.

# In[1]:

import sys
import math
from functools import partial
from collections import namedtuple
from itertools import islice, product


# In[3]:

class DimensionError(ValueError):
    pass


# In[4]:

class Vector(object):
    def __init__(self, *xs):
        self._xs = xs

    @classmethod
    def null_vector(cls, dimension):
        return cls(*([0] * dimension))

    def __repr__(self):
        return "Vector({})".format(", ".join(map(str, self)))

    @property
    def xs(self):
        return self._xs

    @property
    def norm(self):
        return math.sqrt(sum(x * x for x in self))

    @property
    def unit(self):
        return self / self.norm

    @property
    def zero(self):
        return Vector(*((0,) * len(self)))

    def __add__(self, other):
        if len(self) != len(other):
            raise DimensionError
        return Vector(*(x + y for x, y in zip(self, other)))

    def __sub__(self, other):
        return self + (-other)

    def __neg__(self):
        return Vector(*(-x for x in self))

    def __mul__(self, other):
        return Vector(*(x * other for x in self))

    def __rmul__(self, other):
        return self * other

    def __truediv__(self, other):
        return self * (1 / other)

    def __len__(self):
        return len(self.xs)

    def __getitem__(self, item):
        return self.xs[item]


# In[5]:

def test_vector():
    V = Vector
    assert tuple((V(1, 1, 1) + V(2, 3, 4)).xs) == (3, 4, 5)
    assert tuple((V(2, 3, 4) * 2).xs) == (4, 6, 8)
    assert tuple((2 * V(2, 3, 4)).xs) == (4, 6, 8)
    assert tuple((V(2, 4, 6) / 2).xs) == (1, 2, 3)

test_vector()


# In[6]:

Vector(2, 3, 4) + Vector(1, 1, 1)


# In[7]:

class Body(object):
    State = namedtuple("BodyState", "r, v, a, m")

    def __init__(self, r, v, a, m):
        self.r = r
        self.v = v
        if a is not None:
            self.accelerations = [a]
        else:
            self.accelerations = []
        self.m = m

    def move(self, dt):
        self.r = self.r + self.v * dt
        self.v = self.v + self.a * dt

    def add_acceleration(self, a):
        self.accelerations.append(a)

    @property
    def a(self):
        if self.accelerations:
            return sum(
                (accelerate(self) for accelerate in self.accelerations[1:]),
                self.accelerations[0](self)
            )
        else:
            return self.r.zero

    @property
    def f(self):
        return self.m * self.a

    def add_force(self, force):
        self.add_acceleration(lambda self: force(self) / self.m)

    def state(self):
        return self.State(self.r, self.v, self.a, self.m)
    
    def __repr__(self):
        return str(self.state())


# In[8]:

class Planet(object):
    State = namedtuple("PlanetState", "r, v, a, phi, omega, radius, m")

    def __init__(self, phi_0, omega, radius, m):
        self.phi = phi_0
        self.omega = omega
        self.radius = radius
        self.m = m

    def move(self, t, dt):
        self.phi = (self.phi + self.omega * dt) % (2 * math.pi)

    @property
    def r(self):
        return Vector(math.cos(self.phi), math.sin(self.phi)) * self.radius

    @property
    def v(self):
        return Vector(-self.r[1], self.r[0]) * self.omega

    @property
    def a(self):
        return self.omega ** 2 * (-self.r)

    def add_acceleration(self, _a):
        # This body is not influenced by any accelerations.
        # It just rotates.
        pass

    def add_force(self, _force):
        # Same here.
        pass

    def state(self):
        return self.State(
            self.r, self.v, self.a, self.phi,
            self.omega, self.radius, self.m
        )


# In[9]:

class Circle(Body):
    State = namedtuple("CircleState", "r, v, a, m, radius")

    def __init__(self, radius, *args, **kwargs):
        super(Circle, self).__init__(*args, **kwargs)
        self.radius = radius

    def state(self):
        return self.State(
            self.r, self.v, self.a, self.m, self.radius
        )


# In[10]:

class Spring(object):
    def __init__(self, length, D, bodies):
        self.length = length
        self.D = D
        self.bodies = bodies
        bodies[0].add_force(partial(self.restoring_force, bodies[1]))
        bodies[1].add_force(partial(self.restoring_force, bodies[0]))

    def restoring_force(self, other, body):
        return self.D * (
            (body.r - other.r).norm - self.length
        ) * (other.r - body.r).unit


# In[11]:

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

test_spring()


# In[12]:

class Universe(object):
    def __init__(self, gravity, start_time=0):
        self.gravity = gravity
        self.time = start_time
        self.objects = []

    def add(self, object):
        object.add_acceleration(lambda body: self.gravity)
        self.objects.append(object)

    def step(self, dt):
        for body in self.objects:
            body.move(dt)

    def state(self):
        return [object.state() for object in self.objects]

    def simulate(self, end_time, dt, until=lambda: False):
        yield self.state()
        for _ in range(int(end_time // dt)):
            if until():
                return
            self.step(dt)
            yield self.state()
            self.time += dt
    
    def __repr__(self):
        return "Universe(time={0.time}, objects={0.objects})".format(self)


def transpose_states(states, attr="r"):
    attrs = (getattr(state, attr) for state in states)
    return list(zip(*attrs))


def test_transpose_states():
    states = [
        Body.State(Vector(1, 2), None, None, None),
        Body.State(Vector(3, 4), None, None, None),
    ]
    print(transpose_states(states))
    assert transpose_states(states) == [(1, 3), (2, 4)]

test_transpose_states()


G = 6.67 * 10**-11
ε_0 = 8.854187817e-12
π = math.pi


def gravitate(self, other):
    d = other.r - self.r
    return G * self.m * other.m / (d.norm ** 2) * d.unit


def coulomb_force(self, other):
    d = self.r - other.r
    return self.q * other.q / (4 * π * ε_0) * d.unit / (d.norm ** 2)


def implement_universal_force(universe, force):
    """This approach is a little quirky when seen with a physics
    backgroud. However, is it easier to implement this way.
    """
    for body, other in product(universe.objects, repeat=2):
        if body is not other:
            body.add_force(partial(force, other=other))
