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
	"fmt"

	"open-match.dev/open-match/pkg/pb"
)

// Generates match profiles.
func generateProfiles() []*pb.MatchProfile {
	var profiles []*pb.MatchProfile

	modes := []string{"mode.competitive", "mode.casual"}
	regions := []string{"AMER", "EMEA", "APAC"}

	for _, mode := range modes {

		for _, region := range regions {
			
			// Add another loop for skill ranges 
			// For non overlapping pools increments of .25 (4 different skill brackets)
			// For overlapping pools (people on boundaries), at max .05 overlap
			var pools []*pb.Pool
			
			// Offensive Pool
			pools = append(pools, &pb.Pool{
				Name: fmt.Sprintf("pool_%s_%s", mode, region),
				TagPresentFilters: []*pb.TagPresentFilter{
					{
						Tag: region,
					},
				},
				StringEqualsFilters: []*pb.StringEqualsFilter{
					{
						StringArg: "attribute.mode",
						Value:     mode,
					},
				},
				//DoubleRangeFilters: 
				//Added skill based ranges (min,max)
			})

			//Defense pool
			pools = append(pools, &pb.Pool{
				Name: fmt.Sprintf("pool_%s_%s", mode, region),
				TagPresentFilters: []*pb.TagPresentFilter{
					{
						Tag: region,
					},
				},
				StringEqualsFilters: []*pb.StringEqualsFilter{
					{
						StringArg: "attribute.mode",
						Value:     mode,
					},
				},
				//DoubleRangeFilters: 
				//Added skill based ranges (min,max)
			})

			profiles = append(profiles, &pb.MatchProfile{
				Name:  "profile_" + mode + '_' + region,
				Pools: pools,
			})
		}
	}

	return profiles
}
