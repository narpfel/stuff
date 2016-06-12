import random
import sys
import math
from functools import partial
from collections import namedtuple
from itertools import islice, product


# define some physical constants
G = 6.67 * 10**-11
ε_0 = 8.854187817e-12
π = math.pi


class DimensionError(ValueError):
    pass


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
    
    def project_onto(self, other):
        return other.unit * (self * other.unit)

    def __add__(self, other):
        if len(self) != len(other):
            raise DimensionError
        return Vector(*(x + y for x, y in zip(self, other)))

    def __sub__(self, other):
        return self + (-other)

    def __neg__(self):
        return Vector(*(-x for x in self))

    def __mul__(self, other):
        if isinstance(other, Vector):
            if len(self) != len(other):
                raise DimensionError
            return sum(s * o for s, o in zip(self, other))
        else:
            return Vector(*(x * other for x in self))

    def __rmul__(self, other):
        return self * other
    
    def __matmul__(self, other):
        if (len(self), len(other)) != (3, 3):
            raise DimensionError
        x, y, z = self
        a, b, c = other
        return Vector(
            y * c - z * b,
            z * a - x * c,
            x * b - y * a
        )

    def __truediv__(self, other):
        return self * (1 / other)

    def __len__(self):
        return len(self.xs)

    def __getitem__(self, item):
        return self.xs[item]

    def __iter__(self):
        return iter(self.xs)


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


class Circle(Body):
    State = namedtuple("CircleState", "r, v, a, m, radius")

    def __init__(self, radius, *args, **kwargs):
        super(Circle, self).__init__(*args, **kwargs)
        self.radius = radius

    def state(self):
        return self.State(
            self.r, self.v, self.a, self.m, self.radius
        )


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


class Universe(object):
    def __init__(self, gravity, start_time=0):
        self.gravity = gravity
        self.time = start_time
        self.bodies = []

    def __iter__(self):
        return iter(self.bodies)

    def add(self, body):
        if self.gravity.norm:
            body.add_acceleration(lambda body: self.gravity)
        self.bodies.append(body)

    def add_all(self, bodies):
        for body in bodies:
            self.add(body)

    def step(self, dt):
        for body in self.bodies:
            body.move(dt)

    def state(self):
        return [body.state() for body in self.bodies]

    def simulate(self, end_time, dt, until=lambda self: False):
        yield self.state()
        for _ in range(int(end_time // dt)):
            if until(self):
                return
            self.step(dt)
            yield self.state()
            self.time += dt

    def __repr__(self):
        return "Universe(time={0.time}, bodies={0.bodies})".format(self)


def transpose_states(states, attr="r"):
    attrs = (getattr(state, attr) for state in states)
    return list(zip(*attrs))


def gravitate(self, other):
    d = other.r - self.r
    return G * self.m * other.m / (d.norm ** 2) * d.unit


def coulomb_force(self, other):
    d = self.r - other.r
    return self.q * other.q / (4 * π * ε_0) * d.unit / (d.norm ** 2)


def lorentz_force(self, field):
    E, B = field(self.r)
    return self.q * (E + self.v @ B)


def implement_universal_force(universe, force):
    """This approach is a little quirky when seen with a physics
    backgroud. However, is it easier to implement this way.
    """
    for body, other in product(universe.bodies, repeat=2):
        if body is not other:
            body.add_force(partial(force, other=other))


def implement_field(universe, field):
    for body in universe.bodies:
        body.add_force(field)


def kinetic_energy(states):
    energy = 0
    for state in states:
        energy += 0.5 * state.m * state.v.norm ** 2
    return energy


def random_vector(bound, dimension=3):
    return Vector(*[random.uniform(-bound, bound) for _ in range(dimension)])


def friction(body):
    speed = body.v.norm
    if speed < 0.7:
        return -body.v / 0.7
    elif speed < 1:
        return -body.v.unit
    else:
        return -body.v
