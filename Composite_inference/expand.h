#ifndef __HOP_A_EXPAND_
#define __HOP_A_EXPAND_

#include <math.h>
#include <time.h>
#include <stdio.h>
#include <sys/timeb.h>
#include "graph.h"
#include "energy.h"



// Error function to be used by Graph class
#include <mex.h> // for error function
void my_err_func(char* msg)
{
    mexErrMsgIdAndTxt("robustpn:internal_error",msg);
}

// Alpha expansion class
// By Pushmeet Kohli, Lubor Ladicky, Phil Torr

// public functions :

// AExpand(Energy<termType> *e, int maxIter)
// - constructor for the class for solving energy e with maxIter number of iterations 

// void minimize(int *solution)
// - solves energy and saves into the solution array


//typedef double termType;
//typedef Graph<termType, termType, termType> Grapht;

template<typename termType>
class AExpand
{
	public:
        /*
         * Set initial parameters
         */
		AExpand(Energy<termType> *e, int maxIter)
		{
			maxiter = maxIter;
			energy = e;
			nvar = energy->nvar;
			npair = energy->npair;
			nhigher = energy->nhigher;
			nlabel = energy->nlabel;
		}

        /*
         * minimize energy. solution need to be allocated externaly
         */
		termType minimize(int *solution, termType* ee = NULL)
		{
			int label_buf_num;
			int j, en;
			termType E_old, ue, pe, he;

			label_map = solution;

            // estimate the number of edges in the grapg
            for ( j = 0, en = 0 ; j < nhigher ; j++ )
                en += energy->higherElements[j];
                
			g = new Graph<termType, termType, termType>(nvar + 2 * nhigher, npair+2*en+2*nhigher, my_err_func);
			nodes = new node_id_t[nvar + 2 * nhigher]; // nodes in HOpotentials' graph

			E = compute_energy(ue, pe, he); // energy of current solution

			label_buf_num = nlabel;
			

			int iter, label;
			for(iter = 0; (iter < maxiter) && (label_buf_num > 0); iter++) //iterate
			{ 
				for(label = 0; label < nlabel; label++) // for each label:
				{
					E_old = E;
					expand(label);
					g->reset();
					
	        
					E = compute_energy(ue, pe, he); 
					if(E_old == E) label_buf_num--;  //if no change - we might be in optimum, try all other labels
					else label_buf_num = nlabel - 1; // energy changed - retry all labels for new configuration
				}
			}
            if ( iter == maxiter )
                mexWarnMsgIdAndTxt("robustpn:minimize", "Reached maximal number of iterations (%d)", iter);
            
			delete g;
			delete[] nodes;
            if (ee != NULL) {
                ee[0] = ue;
                ee[1] = pe;
                ee[2] = he;
            }
            return E;
		}

	private :
        typedef typename Graph<termType, termType, termType>::node_id node_id_t;
        
		int nvar;   // number of nodes (pixels)
        int npair;  // number of pair-wise potentials
        int nhigher; // number of HOpotentials
        int nlabel; // number of possible lables
		Graph<termType, termType, termType> *g; // min-cut/max-flow class
		node_id_t *nodes; // nodes in graph
		termType E; // current energy of state

		Energy<termType> *energy; // HO-energy formulation
		int *label_map; // current assignment of labels to nodes - **not allocated inside this class**
		int maxiter, i, j; 

        /*
         * Expanding label 
         * In an alpha-expansion step, each node may either retain its label
         * or be labeled "alpha"
         */
		void expand(int label)
		{
			termType constE = 0; 
			bool *is_active;
            int label_bar;

		
			is_active = new bool[nvar]; // all !is_active nodes in the potential will participate in move (may change their labels to alpha)
			
            /* build the graph */
            // unary terms - connect non-active nodes to source/sink
			for(i = 0; i < nvar; i++)
			{
				label_bar = label_map[i];
				if(label_bar == label)
				{
					is_active[i] = true; // active nodes has already label alpha
					constE += energy -> unaryCost[i * nlabel + label];
				}
				else
				{
					is_active[i] = false;
					nodes[i] = g -> add_node(); // add node to graph for this participating variable
					g->add_tweights(nodes[i], energy->unaryCost[i * nlabel + label], energy->unaryCost[i * nlabel + label_bar]); // conect the node like in regular energy minimization                    
				}
			}

			int from, to;
			termType weight;

            // binary-terms
			for(i = 0; i < npair; i++)
			{
				from = energy->pairIndex[2*i];	
				to = energy->pairIndex[2*i+1];
				weight = energy->pairCost[i];

				if(is_active[from] && is_active[to]) continue;
				else if((is_active[from]) && (!is_active[to])) {
                    g->add_tweights(nodes[to], 0, weight);
                    
                } else if((!is_active[from]) && (is_active[to])) {
                    g->add_tweights(nodes[from], 0, weight);
                } else {
					if(label_map[from] == label_map[to]) {
                        g -> add_edge(nodes[from], nodes[to], weight, weight);
                    } else {
						g->add_tweights(nodes[from], 0, weight);
						g->add_edge(nodes[from], nodes[to], 0, weight);
					}
				}
			}

            // Higher-order terms
			termType lambda_a, lambda_b, lambda_m, gamma_b, number_old;
			int maxLabel;

			for(i = 0;i < nhigher; i++)
			{
				maxLabel = getMaxLabel(i); // get dominant label 
	            
				lambda_m = energy->higherCost[i * (nlabel + 1) + nlabel]; // gamma_max 
				lambda_a = energy->higherCost[i * (nlabel + 1) + label];  // gamma_label (alpha)

				nodes[2*i+nvar] = g->add_node(); // add auxilary node m_1
				g->add_tweights(nodes[2 * i + nvar],0,lambda_m - lambda_a); // r_1
				for(j = 0; j < energy->higherElements[i]; j++)
				{
					if (!is_active[energy->higherIndex[i][j]])
						g->add_edge(nodes[2 * i + nvar],nodes[energy->higherIndex[i][j]], 0,
                            energy->higherWeights[i][j]*(lambda_m - lambda_a) / energy->higherTruncation[i]); 
				}
				if((maxLabel == -1) || (maxLabel == label)) // no dominant label
				{
					number_old = 0;
					lambda_b = energy->higherCost[i * (nlabel + 1) + nlabel]; //gamma_max of alpha - no m_0 node
				}
				else // there exist a dominant label
				{
					number_old = cardinality(i, maxLabel);// weights of nodes labeld dominant in current potential (w_i influencing)
					lambda_b = energy->higherCost[i * (nlabel + 1) + maxLabel] + // gamma_d
                        (energy->higherP[i] - number_old) // R_d including weights
							*(energy->higherCost[i * (nlabel + 1) + nlabel] - energy->higherCost[i * (nlabel + 1) + maxLabel]) // gamma_max - gamma_d
                            *(1 / energy->higherTruncation[i]); // 1/Q

					gamma_b = energy->higherCost[i * (nlabel + 1) + maxLabel];

					nodes[2*i+nvar+1] = g->add_node(); // auxilary node m_0
					g->add_tweights(nodes[2 * i + nvar + 1],lambda_m - lambda_b,0); //weight r_0
					for(j = 0; j < energy->higherElements[i]; j++)
						if (label_map[energy->higherIndex[i][j]] == maxLabel) // connect dominant-labeled nodes to m_0
							g->add_edge(nodes[2 * i + nvar + 1],nodes[energy->higherIndex[i][j]], 
                                energy->higherWeights[i][j]*(lambda_m - gamma_b) / energy->higherTruncation[i],0); 
				}
				constE -= lambda_m - (lambda_a + lambda_b); // const offset delta
			}


			g -> maxflow();
			for(i = 0; i<nvar; i++) 
                if((!is_active[i]) && (g->what_segment(nodes[i]) == Graph<termType, termType, termType>::SINK)) 
                    label_map[i] = label; // expand label alpha 
			
			// termType newE = compute_energy(); // - will be done outside this function
			delete[] is_active;
		}

        /*
         * For HOpotential i, choose dominant label (-1 if there is not dominant label) - can be at most one
         * label d s.t.: W(c_d) > P - Q_d,  
         */
		int getMaxLabel(int i)
		{
			int j;
			termType *num_labels = new termType[nlabel];

			for(j = 0;j < nlabel; j++)
				num_labels[j] = 0;

			for(j = 0;j < energy->higherElements[i]; j++)
				num_labels[label_map[energy->higherIndex[i][j]]]+= energy->higherWeights[i][j];

            termType number = 0;
			int maxLabel;

			for(j = 0;j < nlabel; j++)
			{
				if(number <= num_labels[j])
				{
					number = num_labels[j];
					maxLabel = j;
				}
			}

			delete[] num_labels;
			if(number > (energy->higherP[i] - energy->higherTruncation[i])) // Assumes same Q for all labels
                return maxLabel; 
			else 
                return -1;
		}


        /*
         * For HO-potential i sum w_j delta_label(x_j)
         */
		termType cardinality(int i, int label)
		{
			int j;
            termType count_label = 0;

			for(j = 0;j<energy->higherElements[i]; j++)
				if(label_map[energy->higherIndex[i][j]] == label)  
					count_label+=energy->higherWeights[i][j];
			
			return count_label;
		}


        /*
         * Compute current solution's (label_map) energy
         */
		termType compute_energy(termType& ue, termType& pe, termType& he)
		{
			
			int i, j;
			
            ue = 0; // unary term energy
            pe = 0; // pair-wise potentials energy
            he = 0; // high-order potentials energy
            
            // collect Dc - unary terms
			for(i = 0; i < nvar; i++)
				ue += energy->unaryCost[i * nlabel + label_map[i]];
			
            // pair-wise terms. Assuming Sc=[0 1;1 0]
			for(i = 0; i < npair; i++)	{
				if(label_map[energy->pairIndex[2 * i]] != label_map[energy->pairIndex[2 * i + 1]])
					pe += energy->pairCost[i];
			}
			
            // sum w_i delta_j(x_i)
            termType *W = new termType[nlabel];
            
            // collect HOpotenatials terms
			for(i = 0; i < nhigher; i++)    // for each HOpotential
			{
				for(j = 0; j < nlabel; j++) W[j] = 0;

                // count how many nodes are labeled L in the potential i
				for(j = 0; j < energy->higherElements[i]; j++) 
                    W[label_map[energy->higherIndex[i][j]]]+=energy->higherWeights[i][j];

                
				termType cost, minCost = energy->higherCost[(nlabel + 1) * i + nlabel]; // gamma_max

				for(j = 0;j < nlabel; j++)
				{
					cost = energy->higherCost[(nlabel + 1) * i + j] + // gamma_j 
                        (energy->higherP[i] - W[j])     //  P - sum w_i \delta_j(x_c)
							* (energy->higherCost[(nlabel + 1) * i + nlabel]-energy->higherCost[(nlabel + 1) * i + j]) // gamma_max - gamma_j
                            * (1 / energy->higherTruncation[i]);    // 1 / Q
					if (minCost >= cost) minCost = cost;
				}
				// add HOpotential's energy to the total term
				he += minCost;
			}
			delete[] W;

			return ue + pe + he;
		}
};
#endif // __HOP_A_EXPAND_
