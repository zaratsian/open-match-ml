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

// The Frontend in this example continously creates Tickets in batches in Open Match.

import (
	"context"
	"log"
	"time"

	"google.golang.org/grpc"
	"open-match.dev/open-match/pkg/pb"

	"math/rand"
)

const (
	// The endpoint for the Open Match Frontend service.
	omFrontendEndpoint = "open-match-frontend.open-match.svc.cluster.local:50504"
	// Number of tickets created per iteration
	ticketsPerIter = 10
	sleepBetweenIter = 5 // seconds	
)

//var NumTickets int64 = 0

func main() {
	
	// Connect to Open Match Frontend.
	conn, err := grpc.Dial(omFrontendEndpoint, grpc.WithInsecure())
	if err != nil {
		log.Fatalf("Failed to connect to Open Match, got %v", err)
	}

	defer conn.Close()
	fe := pb.NewFrontendServiceClient(conn)
	
	// Simulate client requests (ie. new tickets).
	// For demo purposes.
	// Create a new batch of ticket requests every X seconds.
	for {
		// Used for testing - Wait 5 seconds in-between each new "match request"
		time.Sleep(time.Second * time.Duration(sleepBetweenIter))
		
		start_time := time.Now().Unix()
		log.Printf("start_time: %v", start_time)
		for i := 0; i < ticketsPerIter; i++ {
			time.Sleep(time.Nanosecond * time.Duration(rand.Intn(100000)))

			req := &pb.CreateTicketRequest{
				Ticket: makeTicket(),
			}
			//NumTickets++

			resp, err := fe.CreateTicket(context.Background(), req)
			if err != nil {
				log.Fatalf("Failed to Create Ticket, got %s", err.Error())
			}

			//log.Printf("Ticket created successfully, id: %v\n", resp.Id)
			go deleteOnAssign(fe, resp)

		}
		end_time := time.Now().Unix()
		log.Printf("end_time: %v", end_time)
		elapsed := end_time - start_time
		//elapsed := end_time.Sub(start_time) // Unix for milliseconds
		log.Printf("Processed %v records in %v seconds.", ticketsPerIter, elapsed)
		//log.Printf("Number of Tickets: %v", NumTickets)

	}
}

// deleteOnAssign fetches the Ticket state periodically and 
// deletes the Ticket once it has an assignment.
func deleteOnAssign(fe pb.FrontendServiceClient, t *pb.Ticket) {
	for {
		got, err := fe.GetTicket(context.Background(), &pb.GetTicketRequest{TicketId: t.GetId()})
		if err != nil {
			log.Fatalf("Failed to Get Ticket %v, got %s", t.GetId(), err.Error())
		}

		if got.GetAssignment() != nil {
			//log.Printf("Ticket %v got assignment %v (ticket has been removed).\n", got.GetId(), got.GetAssignment())
			//NumTickets--
			break
		}

		time.Sleep(time.Second * 1)
	}

	_, err := fe.DeleteTicket(context.Background(), &pb.DeleteTicketRequest{TicketId: t.GetId()})
	if err != nil {
		log.Fatalf("Failed to Delete Ticket %v, got %s", t.GetId(), err.Error())
	}
}
