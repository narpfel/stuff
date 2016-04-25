// Implementation of the binop forward macros from Rust’s `num` crate
// <https://github.com/rust-lang/num>. Thanks, Rust team! :-)
//
// Copyright 2013-2014 The Rust Project Developers. See the COPYRIGHT
// file at http://rust-lang.org/COPYRIGHT.
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
// <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
// option. This file may not be copied, modified, or distributed
// except according to those terms.

macro_rules! forward_val_val_binop {
    (impl $imp:ident<$rhs:ty> for $res:ty, $method:ident, $output:ty) => {
        impl $imp<$rhs> for $res {
            type Output = $output;

            #[inline]
            fn $method(self, other: $rhs) -> $output {
                (&self).$method(&other)
            }
        }
    }
}

macro_rules! forward_ref_val_binop {
    (impl $imp:ident<$rhs:ty> for $res:ty, $method:ident, $output:ty) => {
        impl<'a> $imp<$rhs> for &'a $res {
            type Output = $output;

            #[inline]
            fn $method(self, other: $rhs) -> $output {
                self.$method(&other)
            }
        }
    }
}

macro_rules! forward_val_ref_binop {
    (impl $imp:ident<$rhs:ty> for $res:ty, $method:ident, $output:ty) => {
        impl<'a> $imp<&'a $rhs> for $res {
            type Output = $output;

            #[inline]
            fn $method(self, other: &$rhs) -> $output {
                (&self).$method(other)
            }
        }
    }
}

#[macro_export]
macro_rules! forward_all_binop {
    (impl $imp:ident<$rhs:ty> for $res:ty, $method:ident, $output:ty) => {
        forward_val_val_binop!(impl $imp<$rhs> for $res, $method, $output);
        forward_ref_val_binop!(impl $imp<$rhs> for $res, $method, $output);
        forward_val_ref_binop!(impl $imp<$rhs> for $res, $method, $output);
    };
}


#[macro_export]
macro_rules! impl_deref {
    ($typename:ident($($generic_param:ident),*) => $target:ty) => {
        impl<$($generic_param),*> Deref for $typename<$($generic_param),*> {
            type Target = $target;

            fn deref(&self) -> &Self::Target {
                &self.0
            }
        }
    };

    ($typename:ident<$($generic_param:ident),*> => $target:ty) => {
        impl_deref!($typename($($generic_param),*) => $target);
    };

    ($typename:ident => $target:ty) => {
        impl_deref!($typename() => $target);
    };
}


#[cfg(test)]
#[macro_export]
macro_rules! assert_fl_eq {
    ($expected:expr, $actual:expr) => (assert!($expected.approx_eq_ulps(&$actual, 2)));
    ($expected:expr, $actual:expr, $prec:expr) => (assert!($expected.approx_eq_ulps(&$actual, $prec)))
}

#[cfg(test)]
#[macro_export]
macro_rules! assert_v_eq {
    ($expected:expr, $actual:expr) => (assert_fl_eq!($expected, $actual, (2, 2, 2)));
    ($expected:expr, $actual:expr, $prec:expr) => (assert_fl_eq!($expected, $actual, $prec))
}
