use std::ops::{Add, Sub, Mul, Div, Neg};
use std::fmt;


#[derive(Debug)]
pub enum VectorError { VectorNull }


#[derive(Debug, Copy, Clone)]
pub struct Vector3D {
    x: f64,
    y: f64,
    z: f64,
}

impl Vector3D {
    pub fn new<X: Into<f64>, Y: Into<f64>, Z: Into<f64>>(x: X, y: Y, z: Z) -> Vector3D {
        Vector3D {
            x: x.into(),
            y: y.into(),
            z: z.into(),
        }
    }

    pub fn null_vector() -> Vector3D {
        Vector3D::new(0, 0, 0)
    }

    fn is_null(&self) -> bool {
        self.x == 0.0 && self.y == 0.0 && self.z == 0.0
    }

    pub fn norm_squared(&self) -> f64 {
        self * self
    }

    pub fn norm(&self) -> f64 {
        self.norm_squared().sqrt()
    }

    pub fn unit(&self) -> Result<Self, VectorError> {
        if self.is_null() {
            Err(VectorError::VectorNull)
        }
        else {
            Ok(self / self.norm())
        }
    }

    pub fn angle_to(&self, other: &Vector3D) -> Result<f64, VectorError> {
        if self.is_null() || other.is_null() {
            Err(VectorError::VectorNull)
        }
        else {
            Ok(f64::acos(self * other / (self.norm_squared() * other.norm_squared()).sqrt()))
        }
    }

    pub fn project_onto(&self, other: &Self) -> Result<Self, VectorError> {
        let other_unit = try!(other.unit());
        Ok(other_unit * (self * other_unit))
    }

    /// Decompose a vector into a vector parallel to `parallel_direction` and a vector
    /// perpendicular to that direction so that these two vectors add up to `self`.
    pub fn decompose(&self, parallel_direction: &Self) -> Result<(Self, Self), VectorError> {
        let parallel = try!(self.project_onto(parallel_direction));
        Ok((parallel, self - parallel))
    }
}


impl Default for Vector3D {
    fn default() -> Vector3D {
        Vector3D::null_vector()
    }
}


forward_all_binop!(impl Mul<Vector3D> for Vector3D, mul, f64);

impl<'a, 'b> Mul<&'b Vector3D> for &'a Vector3D {
    type Output = f64;

    #[inline]
    fn mul(self, other: &Vector3D) -> Self::Output {
        self.x * other.x + self.y * other.y + self.z * other.z
    }
}

forward_all_binop!(impl Mul<f64> for Vector3D, mul, Vector3D);

impl<'a, 'b> Mul<&'b f64> for &'a Vector3D {
    type Output = Vector3D;

    #[inline]
    fn mul(self, other: &f64) -> Vector3D {
        Vector3D::new(other * self.x, other * self.y, other * self.z)
    }
}

forward_all_binop!(impl Mul<Vector3D> for f64, mul, Vector3D);

impl<'a, 'b> Mul<&'b Vector3D> for &'b f64 {
    type Output = Vector3D;

    #[inline]
    fn mul(self, other: &Vector3D) -> Vector3D {
        other * self
    }
}

forward_all_binop!(impl Div<f64> for Vector3D, div, Vector3D);

impl<'a, 'b> Div<&'b f64> for &'a Vector3D {
    type Output = Vector3D;

    #[inline]
    fn div(self, other: &f64) -> Vector3D {
        1.0 / other * self
    }
}

forward_all_binop!(impl Add<Vector3D> for Vector3D, add, Vector3D);

impl<'a, 'b> Add<&'b Vector3D> for &'a Vector3D {
    type Output = Vector3D;

    #[inline]
    fn add(self, other: &Vector3D) -> Self::Output {
        Vector3D::new(self.x + other.x, self.y + other.y, self.z + other.z)
    }
}

forward_all_binop!(impl Sub<Vector3D> for Vector3D, sub, Vector3D);

impl<'a, 'b> Sub<&'b Vector3D> for &'a Vector3D {
    type Output = Vector3D;

    #[inline]
    fn sub(self, other: &Vector3D) -> Vector3D {
        -other + self
    }
}

impl Neg for Vector3D {
    type Output = Self;

    #[inline]
    fn neg(self) -> Self {
        -&self
    }
}

impl<'a> Neg for &'a Vector3D {
    type Output = Vector3D;

    #[inline]
    fn neg(self) -> Vector3D {
        -1.0 * self
    }
}

impl PartialEq for Vector3D {
    #[inline]
    fn eq(&self, other: &Vector3D) -> bool {
        self.x == other.x && self.y == other.y && self.z == other.z
    }
}

impl fmt::Display for Vector3D {
    fn fmt(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
        formatter.write_str(&format!("Vector3D(x={}, y={}, z={})", self.x, self.y, self.z))
    }
}


#[cfg(test)]
mod tests {
    extern crate float_cmp;

    use std::f64::consts;

    use super::*;
    use self::float_cmp::{ApproxEqUlps, Ulps};

    impl Ulps for Vector3D {
        type U = (i64, i64, i64);

        fn ulps(&self, other: &Self) -> Self::U {
            (self.x.ulps(&other.x), self.y.ulps(&other.y), self.z.ulps(&other.z))
        }
    }

    impl ApproxEqUlps for Vector3D {
        fn approx_eq_ulps(&self, other: &Self, ulps: Self::U) -> bool {
            self.x.approx_eq_ulps(&other.x, ulps.0)
            && self.y.approx_eq_ulps(&other.y, ulps.1)
            && self.z.approx_eq_ulps(&other.z, ulps.2)
        }
    }

    const A: Vector3D = Vector3D { x: 2.0, y: 3.0, z: 4.0 };
    const B: Vector3D = Vector3D { x: 1.0, y: 2.0, z: 1.5 };
    const C: Vector3D = Vector3D { x: 1.0, y: 1.0, z: 2.5 };
    const NULL_VECTOR: Vector3D = Vector3D { x: 0.0, y: 0.0, z: 0.0 };

    #[test]
    fn test_add() {
        assert_v_eq!(A, B + C);
        assert_v_eq!(A, A + NULL_VECTOR);
    }

    #[test]
    fn test_sub() {
        assert_v_eq!(B, A - C);
        assert_v_eq!(A, A - NULL_VECTOR);
    }

    #[test]
    fn test_neg() {
        assert_v_eq!(Vector3D::new(-2.0, -3.0, -4.0), -A);
    }

    #[test]
    fn test_mul_vector_f() {
        assert_v_eq!(Vector3D::new(6.0, 9.0, 12.0), A * 3.0);
        assert_v_eq!(NULL_VECTOR, NULL_VECTOR * 42.0);
        assert_v_eq!(NULL_VECTOR, B * 0.0);
    }

    #[test]
    fn test_mul_f_vector() {
        assert_v_eq!(Vector3D::new(6.0, 9.0, 12.0), 3.0 * A);
        assert_v_eq!(NULL_VECTOR, 42.0 * NULL_VECTOR);
        assert_v_eq!(NULL_VECTOR, 0.0 * B);
    }

    #[test]
    fn test_mul_vector_vector() {
        assert_fl_eq!(14.0, A * B);
        assert_fl_eq!(0.0, C * NULL_VECTOR);
    }

    #[test]
    fn test_div() {
        assert_v_eq!(Vector3D::new(1.0, 1.5, 2.0), A / 2.0);
        assert_v_eq!(NULL_VECTOR, NULL_VECTOR / 22.0);
    }

    #[test]
    fn test_norm() {
        assert_fl_eq!(Vector3D::new(3.0, 4.0, 1.0).norm(), 26f64.sqrt());
        assert_fl_eq!(NULL_VECTOR.norm(), 0.0);
    }

    #[test]
    fn test_vector_new_into() {
        assert_v_eq!(Vector3D::new(20.0, 3.0, 2.0), Vector3D::new(20, 3f32, 2u8));
    }

    #[test]
    fn test_angle_to_perpendicular_vector() {
        let maybe_angle = Vector3D::new(0, 1, 1).angle_to(&Vector3D::new(1, 0, 0));
        assert!(maybe_angle.is_ok());
        assert_fl_eq!(maybe_angle.unwrap(), consts::FRAC_PI_2);
    }

    #[test]
    fn test_angle_to_parallel_vector() {
        let maybe_angle = Vector3D::new(1, 0, 3).angle_to(&Vector3D::new(1, 0, 3));
        assert!(maybe_angle.is_ok());
        let angle = maybe_angle.unwrap();
        println!("{:?}", angle);
        assert_fl_eq!(angle, 0.0);
    }
}
