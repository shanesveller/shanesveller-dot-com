package sieve

import (
	"math"
	"sort"
)

func SieveOfEratosthenes(limit int) []int {
	primes := make([]int, 0, limit)
	isPrimeList := make(map[int]bool)

	for i := 2; i <= limit; i++ {
		isPrimeList[i] = true
	}

	for p := 2; p <= limit; p++ {
		if isPrimeList[p] == true {
			primes = append(primes, int(p))
			for i := p * 2; i < limit; i += p {
				isPrimeList[i] = false
				// fmt.Println(i, "is a mulitiple of", p, "and therefore is not prime.")
			}
		}
	}

	return primes
}

func SieveOfEratosthenesCountLimit(limit int) []int {
	primes := make([]int, 0, limit)
	isPrimeList := make(map[int]bool)

	i := 2
	isPrimeList[i] = true

	for len(primes) < limit {
		if v, ok := isPrimeList[i]; v || !ok {
			primes = append(primes, i)
		}

		for j := 2 * i; j < limit*limit; j += i {
			isPrimeList[j] = false
		}

		i++

	}

	return primes
}

// ax^2 + bx + c = 0
func Quadratic(a, b, c float64) []float64 {
	roots := make([]float64, 2)

	discriminant := (b * b) - (4 * a * c)

	roots[0] = (-b + math.Sqrt(discriminant)) / (2.0 * a)
	roots[1] = (-b - math.Sqrt(discriminant)) / (2.0 * a)

	sort.Float64s(roots)

	return roots
}

func SieveOfAtkin(limit int) []int {
	// slice of [2,3] with capacity of limit
	primes := append(make([]int, 0, limit), 2, 3)
	// list[i] will indicate whether i is prime or not, for easy flipping
	isPrimeList := make(map[int]bool, limit)
	// declare initially-known primes to be such
	for _, prime := range primes {
		isPrimeList[prime] = true
	}

	rootOfLimit := int(math.Ceil(math.Sqrt(float64(limit))))

	var n, x2, y2 int

	for x := 1; x <= rootOfLimit; x++ {
		for y := 1; y <= rootOfLimit; y++ {
			x2 = int(math.Pow(float64(x), 2))
			y2 = int(math.Pow(float64(y), 2))
			n = 4*x2 + y2

			if n <= limit && (n%12 == 1 || n%12 == 5) {
				isPrimeList[n] = !isPrimeList[n]
			}

			n = 3*x2 + y2

			if n <= limit && n%12 == 7 {
				isPrimeList[n] = !isPrimeList[n]
			}

			n = 3*x2 - y2

			if x > y && n <= limit && n%12 == 11 {
				isPrimeList[n] = !isPrimeList[n]
			}
		}
	}

	for i := 5; i <= rootOfLimit; i++ {
		if isPrimeList[i] {
			for n = 1; n*i*i <= limit; n++ {
				isPrimeList[n*i*i] = false
			}

		}
	}

	for i := 5; i <= limit; i++ {
		if isPrimeList[i] {
			primes = append(primes, i)
		}
	}

	return primes

}
