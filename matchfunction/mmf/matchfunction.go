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

package mmf

import (
	"fmt"
	"log"
	"time"

	"open-match.dev/open-match/pkg/matchfunction"
	"open-match.dev/open-match/pkg/pb"
)

// This match function fetches all the Tickets for all the pools specified in
// the profile. It uses a configured number of tickets from each pool to generate
// a Match Proposal. It continues to generate proposals until one of the pools
// runs out of Tickets.
const (
	matchName                 = "multipool-matchfunction"
	ticketsPerPoolPerMatch    = 4
	desired_offensive_players = 2
	desired_defensive_players = 2
)

// Run is this match function's implementation of the gRPC call defined in api/matchfunction.proto.
func (s *MatchFunctionService) Run(req *pb.RunRequest, stream pb.MatchFunction_RunServer) error {

	// Query tickets for the pools specified in the Match Profile.
	//fmt.Printf("\n[ STEP 1 ] Generating proposals for function %v. Profile: %+v\n", req.GetProfile().GetName(), req.GetProfile())
	poolTickets, err := matchfunction.QueryPools(stream.Context(), s.queryServiceClient, req.GetProfile().GetPools())
	//fmt.Printf("\n[ STEP 2 ] Number of Pool Tickets: %v\n", len(poolTickets))
	//fmt.Printf("\n[ STEP 3 ] Pool Tickets: %v\n", poolTickets)
	if err != nil {
		log.Printf("Failed to query tickets for the given pools, got %s", err.Error())
		return err
	}

	// Generate proposals
	proposals, err := makeMatches(req.GetProfile(), poolTickets)
	if err != nil {
		log.Printf("Failed to generate matches, got %s", err.Error())
		return err
	}

	// Stream the generated proposals back to Open Match.
	fmt.Printf("\n[ STEP 3 ] Streaming %v proposals to Open Match\n", len(proposals))
	for _, proposal := range proposals {
		fmt.Printf("\n[ STEP 4 ] Proposal: %v\n", proposal)
		if err := stream.Send(&pb.RunResponse{Proposal: proposal}); err != nil {
			log.Printf("Failed to stream proposals to Open Match, got %s", err.Error())
			return err
		}
	}

	return nil
}

func makeMatches(p *pb.MatchProfile, poolTickets map[string][]*pb.Ticket) ([]*pb.Match, error) {
	var matches []*pb.Match
	count := 0
	for {
		insufficientTickets := false
		matchTickets := []*pb.Ticket{}

		offensive_players := 0
		defensive_players := 0
		
		for pool, tickets := range poolTickets {

			if len(tickets) < ticketsPerPoolPerMatch {
				// This pool is completely drained out. Stop creating matches.
				insufficientTickets = true
				break
			}

			// Add Tickets to the Match Profile.
			for i,ticket := range tickets {
				fmt.Printf("\nSingle Ticket %v: %v\n", i, ticket)

				offense := ticket.SearchFields.DoubleArgs["skill.offense"]
				defense := ticket.SearchFields.DoubleArgs["skill.defense"]

				if offense > 0.50 {
					// Add Ticket to Match Profile as Offensive Player

				} else if defense > 0.50 {
					// Add Ticket to Match Profile as Defensive Player

				}
				
			}
			matchTickets = append(matchTickets, tickets[0:ticketsPerPoolPerMatch]...)

			// Remove Tickets from this Pool
			poolTickets[pool] = tickets[ticketsPerPoolPerMatch:]
		}

		if insufficientTickets {
			break
		}

		matches = append(matches, &pb.Match{
			MatchId:       fmt.Sprintf("profile-%v-time-%v-%v", p.GetName(), time.Now().Format("2006-01-02T15:04:05.00"), count),
			MatchProfile:  p.GetName(),
			MatchFunction: matchName,
			Tickets:       matchTickets,
		})

		count++
	}

	return matches, nil
}
