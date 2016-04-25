use std::f64::EPSILON;
use std::fs::File;
use std::io::Write;
use std::path::Path;

extern crate rand;
use rand::{Rand, Rng, SeedableRng};
use rand::distributions::{IndependentSample, Range};

#[macro_use]
mod helpers;

mod vector;
pub use vector::Vector3D;


// TODO: `(-1f64).next_after(0)` is unstable.
const NEG_1_PLUS_EPS: f64 = -1f64 + EPSILON;

const SIMULATIONS: usize = 10_000;


impl Rand for Vector3D {
    /// Random unit vector, method 4 from Marsaglia, G. “Choosing a Point from the Surface of a
    /// Sphere.” Ann. Math. Stat. 43, 645-646, 1972.
    /// See https://projecteuclid.org/download/pdf_1/euclid.aoms/1177692644.
    fn rand<R: Rng>(rng: &mut R) -> Vector3D {
        let range = Range::new(NEG_1_PLUS_EPS, 1.0);
        loop {
            let v1 = range.ind_sample(rng);
            let v2 = range.ind_sample(rng);
            let s = v1.powi(2) + v2.powi(2);
            if s < 1.0 {
                return Vector3D::new(
                    2. * v1 * (1. - s).sqrt(),
                    2. * v2 * (1. - s).sqrt(),
                    1. - 2. * s
                );
            }
        }
    }
}


fn random_walk_continuous<R: Rng>(rng: &mut R, steps: usize, step_length: f64) -> Vector3D {
    let mut position = Vector3D::null_vector();
    for step in rng.gen_iter::<Vector3D>().take(steps) {
        position = position + step_length * step;
    }
    position
}


fn random_walk_discrete<R: Rng>(rng: &mut R, steps: usize, step_length: f64) -> Vector3D {
    let possibilities: Vec<_> = [
        Vector3D::new(1, 0, 0),
        Vector3D::new(-1, 0, 0),
        Vector3D::new(0, 1, 0),
        Vector3D::new(0, -1, 0),
        Vector3D::new(0, 0, 1),
        Vector3D::new(0, 0, -1),
    ].iter().map(|v| v * step_length).collect();

    let mut position = Vector3D::null_vector();

    for _ in 0..steps {
        position = position + rng.choose(&possibilities).unwrap();
    }
    position
}


fn simulate_random_walks<R: Rng, F: Fn(&mut R, usize, f64) -> Vector3D>(
    rng: &mut R,
    steps: usize,
    step_length: f64,
    simulations: usize,
    random_walk: F
) -> f64 {
    (0..simulations)
        .map(|_| random_walk(rng, steps, step_length).norm_squared())
        // TODO: `Iterator::sum` is unstable.
        .fold(0f64, |acc, x| acc + x) / (simulations as f64)
}


fn write_csv_file<P: AsRef<Path>>(path: P, values: Vec<f64>) -> std::io::Result<()> {
    let mut file = try!(File::create(path));
    for (i, value) in values.iter().enumerate() {
        try!(write!(file, "{} {}\n", i, value));
    }
    Ok(())
}


fn main() {
    let mut rng = rand::StdRng::from_seed(&[1, 42, 3, 7]);

    for step_length in &[2.0, 3.0, 4.0] {
        write_csv_file(
            format!("continuous{}.csv", step_length),
            (0..100).map(
                |steps| simulate_random_walks(
                    &mut rng, steps, *step_length, SIMULATIONS, random_walk_continuous
                )
            ).collect()
        ).expect("Could not write csv file.");

        write_csv_file(
            format!("discrete{}.csv", step_length),
            (0..100).map(
                |steps| simulate_random_walks(
                    &mut rng, steps, *step_length, SIMULATIONS, random_walk_discrete
                )
            ).collect()
        ).expect("Could not write csv file.");
    }
}
