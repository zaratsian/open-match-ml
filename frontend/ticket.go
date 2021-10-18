// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"math/rand"

	"open-match.dev/open-match/pkg/pb"
)

func makeTicket() *pb.Ticket {

	ticket := &pb.Ticket{
		SearchFields: &pb.SearchFields{
			// https://open-match.dev/site/docs/reference/api/#searchfields
			Tags: []string{
				region(),
			},
			StringArgs: map[string]string{
				"attribute.mode": gameMode(),
			},
			DoubleArgs: map[string]float64{
				"score": getScore(),
				"skill.offense": positionStrength(),
				"skill.defense": positionStrength(),
			},

		},
	}

	return ticket
}

func gameMode() string {
	modes := []string{"mode.competitive", "mode.casual"}
	return modes[rand.Intn(len(modes))]
}

func region() string {
	regions := []string{"AMER", "EMEA", "APAC"}
	return regions[rand.Intn(len(regions))]
}

func getScore() float64 {
	score := 1200 + (rand.Intn(500) - rand.Intn(500))
	return float64(score)
}

func positionStrength() float64 {
	value := rand.Float64()
	return value
}