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
    
    init(numBands: UInt = 3, numSamples: UInt = 10000) {
        let numSamplesSqrt = UInt(sqrtf(Float(numSamples)))
        self.numBands = numBands
        self.numSamples = numSamplesSqrt * numSamplesSqrt
        numCoeffs = numBands * numBands
        // init samples with 0-arrays, so they can be indexed in setupSphericalSamples
        let coefficients = [Double](count: Int(numCoeffs), repeatedValue: 0)
        let emptySample = SHSample(sph: Spherical(), vec: Vector3(), coeff: coefficients)
        samples = [SHSample](count: Int(self.numSamples), repeatedValue: emptySample)
        setupSphericalSamples(numSamplesSqrt)
    }
    
    /**
     * @brief Initializes the SHSamples
     * fill an N*N*2 array with uniformly distributed
     * samples across the sphere using jittered stratification
     * !!!!!!!!! THIS LOOP IS SLOW! In C++ is just a few ms...
    */
    func setupSphericalSamples(numSamplesSqrt: UInt) {
        var i = 0 // array index
        let oneoverN = 1.0/Double(numSamplesSqrt)
        for a in 0...(numSamplesSqrt-1) {
            for b in 0...(numSamplesSqrt-1) {
                // generate unbiased distribution of spherical coords
                let x = (Double(a)+Double(Randf())) * oneoverN; //do not reuse results
                let y = (Double(b)+Double(Randf())) * oneoverN; //each sample must be random
                let θ = 2.0 * acos(sqrt(1.0 - x))
                let φ = 2.0 * π * y
                samples[i].sph = Spherical(r: 1.0, θ: Float(θ), φ: Float(φ))
                // convert spherical coords to unit vector
                samples[i].vec = samples[i].sph.ToVector3()
                // precompute all SH coefficients for this sample
                for l in 0...(Int(numBands)-1) {
                    for m in -l...l {
                        let ci = l * (l+1) + m // coefficient index
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
}


