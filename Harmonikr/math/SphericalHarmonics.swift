//
//  SphericalHarmonics.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/8/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//
//  Ref. "Spherical Harmonics Lighting: The Gritty Details",
//      Robin Green

import Foundation


class SphericalHarmonics {
    /** SphericalHarmonics Samples */
    struct SHSample {
        var sph:    Spherical
        var vec:    Vector3
        var coeff:  [Double]
    }
    
    let numBands    : UInt
    let numCoeffs   : UInt
    let numSamples  : UInt
    var samples     : [SHSample]
    var coeffs      : [Vector3]
    var mIrradiance : [Matrix4]     ///< Irradiance matrices
    
    init(numBands: UInt = 3, numSamples: UInt = 10000) {
        let numSamplesSqrt = UInt(sqrtf(Float(numSamples)))
        self.numBands = numBands
        self.numSamples = numSamplesSqrt * numSamplesSqrt
        numCoeffs = numBands * numBands
        mIrradiance = Array(count: 3, repeatedValue: Matrix4())
        // init samples with 0-arrays, so they can be indexed in setupSphericalSamples
        let coefficients = [Double](count: Int(numCoeffs), repeatedValue: 0)
        let emptySample = SHSample(sph: Spherical(), vec: Vector3(), coeff: coefficients)
        samples = [SHSample](count: Int(self.numSamples), repeatedValue: emptySample)
        coeffs = [Vector3](count: Int(numCoeffs), repeatedValue: Vector3())
        setupSphericalSamples(numSamplesSqrt)
    }
    
    /**
     * @brief Initializes the SHSamples
     * fill an N*N*2 array with uniformly distributed
     * samples across the sphere using jittered stratification
    */
    func setupSphericalSamples(numSamplesSqrt: UInt) {
        var i = 0 // array index
        let oneoverN = 1.0/Double(numSamplesSqrt)
        for a in 0..<numSamplesSqrt {
            for b in 0..<numSamplesSqrt {
                // generate unbiased distribution of spherical coords
                let x = (Double(a)+Double(Randf())) * oneoverN; //do not reuse results
                let y = (Double(b)+Double(Randf())) * oneoverN; //each sample must be random
                let θ = 2.0 * acos(sqrt(1.0 - x))
                let φ = 2.0 * π * y
                let sph = Spherical(r: 1.0, θ: Float(θ), φ: Float(φ))
                samples[i].sph = sph
                // convert spherical coords to unit vector
                samples[i].vec = sph.ToVector3()
                // precompute all SH coefficients for this sample
                for l in 0..<Int(numBands) {
                    for m in -l...l {
                        let ci = l * (l+1) + m // coefficient index
                        // accessing the array here seems to be a bit slow...
                        samples[i].coeff[ci] = SH(l: l,m: m,θ: θ,φ: φ)
                    }
                }
                ++i
            }
        }
    } // func setupSphericalSamples
    
    /// evaluate an Associated Legendre Polynomial P(l,m,x) at x
    func P(#l: Int, m: Int, x: Double) -> Double {
        var pmm : Double = 1.0
        if (m>0) {
            let somx2 = sqrt((1.0-x)*(1.0+x))
            var fact = 1.0
            for i in 1...m {
                pmm *= (-fact) * somx2;
                fact += 2.0;
            }
        }
        if (l==m) {
            return pmm
        }
        var pmmp1 = x * (2.0*Double(m)+1.0) * pmm
        if (l==m+1) {
            return pmmp1
        }
        var pll : Double = 0.0
        for var ll = m+2; ll<=l; ++ll {
            pll = ( (2.0*Double(ll)-1.0)*x*pmmp1-(Double(ll+m)-1.0)*pmm ) / Double(ll-m)
            pmm = pmmp1
            pmmp1 = pll
        }
        return pll
    }
    
    /// renormalization constant for SH function
    func K(#l: Int, m: Int) -> Double {
        let temp = ((2.0*Double(l)+1.0)*Factorial(l-m)) / (4.0*π*Factorial(l+m))
        return sqrt(temp)
    }
    
    /**
    * @return a point sample of a Spherical Harmonic basis function
    *  l is the band, range [0..N]
    *  m in the range [-l..l]
    *  theta in the range [0..Pi]
    *  phi in the range [0..2*Pi]
    */
    func SH(#l: Int, m: Int, θ: Double, φ: Double) -> Double {
        let sqrt2 : Double = sqrt(2.0)
        if (m==0) {
            return K(l: l,m: 0) * P(l: l,m: m,x: cos(θ))
        }
        else if (m>0) {
            return sqrt2 * K(l: l, m: m) * cos(Double(m)*φ) * P(l: l,m: m,x: cos(θ))
        }
        else {
            return sqrt2 * K(l: l, m: -m) * sin(Double(-m)*φ) * P(l: l,m: -m,x: cos(θ))
        }
    }
    
    /**
     * Projects a polar function and computes the SH Coeffs
     * @param fn the Polar Function. If the polar function is an image, pass a function that retrieves (R,G,B) values from it given a spherical coordinate.
     */
    func projectPolarFn(fn: (Float, Float) -> Vector3) -> [Vector3] {
        let weight : Double = 4.0*π
        // for each sample
        for i : Int in 0...(numSamples-1) {
            let θ = samples[i].sph.θ
            let φ = samples[i].sph.φ
            for n : Int in 0...(numCoeffs-1) {
                coeffs[n] += fn(θ,φ) * Float(samples[i].coeff[n])
            }
        }
        // divide the result by weight and number of samples
        let factor = weight / Double(numSamples)
        for i : Int in 0...(numCoeffs-1) {
            coeffs[i] *= Float(factor)
        }
        
        // compute matrices for later
        computeIrradianceApproximationMatrices()
        
        return coeffs
    }
    
    /**
     * Reconstruct the approximated function for the given input direction,
     * given in spherical/polar coordinates
     */
    func reconstruct(#θ: Double, φ: Double) -> Vector3
    {
        var o = Vector3();
        for l in 0..<Int(numBands) {
            for m in -l...l {
                let ci = l * (l+1) + m // coefficient index
                let sh = Float(SH(l: l,m: m,θ: θ,φ: φ))
                o += sh * coeffs[ci];
            }
        }
        return o;
    }
    
    /**
     * Reconstruct the approximated function for the given input direction
     */
    func reconstruct(direction: Vector3) -> Vector3
    {
        var sp = Spherical(v: direction);
        return reconstruct(θ: Double(sp.θ), φ: Double(sp.φ))
    }
    
    
    /**
     * Computes matrix M used to approximate irradiance E(n).
     * For normal direction n, E(n) = n^ * M * n
     * @see "An efficient representation for Irradiance Environment Maps"
     */
    func computeIrradianceApproximationMatrices() {
        if numBands < 3 {
            println("Not enough coefficients!")
            return
        }
        let a0 = PI * 1.0
        let a1 = PI * 2.0/3.0
        let a2 = PI * 1.0/4.0
        let k0 = (1.0/4.0) * sqrtf(15.0/PI) * a2
        let k1 = (1.0/4.0) * sqrtf(3.0/PI) * a1
        let k2 = (1.0/2.0) * sqrtf(1.0/PI) * a0
        let k3 = (1.0/4.0) * sqrtf(5.0/PI) * a2
    
        // coeff: L00, L1-1, L10, L11, L2-2, L2-1, L20, L21, L22
    
        // for every color channel
        for i in 0...2 {
            mIrradiance[i][0,0] = k0 * coeffs[8][i]
            mIrradiance[i][1,0] = k0 * coeffs[4][i]
            mIrradiance[i][2,0] = k0 * coeffs[7][i]
            mIrradiance[i][3,0] = k1 * coeffs[3][i]
            mIrradiance[i][0,1] = k0 * coeffs[4][i]
            mIrradiance[i][1,1] = -k0 * coeffs[8][i]
            mIrradiance[i][2,1] = k0 * coeffs[5][i]
            mIrradiance[i][3,1] = k1 * coeffs[1][i]
            mIrradiance[i][0,2] = k0 * coeffs[7][i]
            mIrradiance[i][1,2] = k0 * coeffs[5][i]
            mIrradiance[i][2,2] = 3.0 * k3 * coeffs[6][i]
            mIrradiance[i][3,2] = k1 * coeffs[2][i]
            mIrradiance[i][0,3] = k1 * coeffs[3][i]
            mIrradiance[i][1,3] = k1 * coeffs[1][i]
            mIrradiance[i][2,3] = k1 * coeffs[2][i]
            mIrradiance[i][3,3] = k2 * coeffs[0][i] - k3 * coeffs[6][i]
        }
    } // computeIrradianceApproximationMatrices
    
    /**
     * Computes the approximate irradiance for the given normal direction
     *  E(n) = n^ * M * n
     */
    func GetIrradianceApproximation(normal: Vector3) -> Vector3 {
        var v = Vector3(value: 0)
        // In the original paper, (x,y,z) = (sinθcosφ, sinθsinφ, cosθ),
        // but in our Spherical class the vertical axis cosθ is Y
        var n = Vector4(x: -normal.z, y: -normal.x, z: normal.y, w: 1)
        // for every color channel
        v.x = Dot(n, mIrradiance[0] * n)
        v.y = Dot(n, mIrradiance[1] * n)
        v.z = Dot(n, mIrradiance[2] * n)
        return v
    }
}


