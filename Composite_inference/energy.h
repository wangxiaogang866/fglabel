#ifndef __ENERGY_H__
#define __ENERGY_H__

// Energy class
// By Pushmeet Kohli, Lubor Ladicky, Phil Torr

// public variables :

// - nlabel - number of labels
// - nvar - number of nodes/variables
// - npair - number of pairwise connections
// - nhigher - number of cliques/segments
// - unaryCost - array of unary costs [nvar * nlabel]
// - pairIndex - array of pairs of indexes of nodes for each pairwise connection [2 * npair]
// - pairCosts - array of costs for pairwise Potts model [npair]
// - higherElements - array of number of elements in each segment [nhigher]
// - higherCosts - array of higher order costs {gamma_k, gammamax} for each segment [nhigher * (nlabel + 1)]
// - higherTruncation - array of Truncation parameter Q for each segment [nhigher]
// - higherIndex - array of arrays of indexes of nodes for each segment [nhigher] x [higherElements[]]
// - higherWeights - array of arrays of weights of nodes for each segment [nhigher] x [higherElements[]]  // BAGON


// public functions :

// Energy(int nLabel, int nVar, int nPair, int nHigher)
// - constructor for the class initializing number of labels, nodes, pairwise connections and segments

// void AllocateHigherIndexes()
// - allocates memory for list of indexes within each clique
// - this function has to be called after number of nodes in each segment (higherElements) is initialized

template<typename termType>
class AExpand;

template<typename termType> 
class Energy
{
    private:
		termType *unaryCost;    // (#labels)x(#nodes) DataCost unaryCost(L,i) -> assign node i label L
        termType *pairCost;       // if nodes in pair (i,j) are labeled differently, assumes Sc = [0 1;1 0]  
        termType *higherCost;  // gamma_k values for the HOpotentials (#labels+1)x(#higher), last entry at each column is gamma_max
        termType *higherTruncation; // Q_k values - one per HOpotential
        termType **higherWeights; // BAGON: w_i weights for each node at a HOpotential
        termType *higherP; // BAGON: sum w_i of each HOpotential (P value)
		int nlabel; // number of labels
        int nvar;    // number of nodes in the graph (i.e., pixels)
        int npair;  // pair-wise potentials, assuming Sc=[0 1;1 0];
        int nhigher; // number of higher order potentials
		int *pairIndex; // (2x#pairs)  indices of participating nodes for each pair-wise potential
        int **higherIndex; // an array per HOpotential with indices of participating nodes
        int *higherElements; // for each HOpotential - the number of nodes participating in it, i.e., there are higherElements[j-1] nodes in HOpotential j.

        friend class AExpand<termType>;
        
    public:
		
        /*
         * Initilize a HOpotential-enabled energy term, with:
         * the number of possible labels, number of nodes, number of pair-wise and HO potentials
         */
		Energy(int nLabel, int nVar, int nPair, int nHigher):
            unaryCost(NULL), pairCost(NULL), higherCost(NULL),
            higherTruncation(NULL), higherWeights(NULL), higherP(NULL),
            pairIndex(NULL), higherIndex(NULL), higherElements(NULL)
		{
			nlabel = nLabel;
			nvar = nVar;
			npair = nPair;
			nhigher = nHigher;

			unaryCost = new termType[nvar * nlabel];
			pairIndex = new int[npair * 2];
			pairCost = new termType[npair];

			higherCost = new termType[nhigher * (nlabel + 1)];
			higherElements = new int[nhigher];
            memset(higherElements, 0, nhigher * sizeof(int)); // make sure they are zero
			higherTruncation = new termType[nhigher];
			higherIndex = new int *[nhigher];
			memset(higherIndex, 0, nhigher * sizeof(int *));
            higherWeights = new termType *[nhigher]; // BAGON
            memset(higherWeights, 0, nhigher * sizeof(termType*)); // BAGON
            higherP = new termType[nhigher];
		}
        /*
         * Add data term, an array of size (#labels)x(#nodes)
         * The array is *NOT* being copy
         */        
        void SetUnaryCost(const termType* dc)
        {
             memcpy(unaryCost, dc, nlabel*nvar*sizeof(termType));
        }
        /*
         * Set the pair-wise energy terms
         * pairs is 2xnpair indices of pairs
         * sc is an array of npair
         */
        void SetPairCost(const int * pairs, const termType* sc)
        {
            memcpy(pairIndex, pairs, 2*npair*sizeof(int));
            memcpy(pairCost, sc, npair*sizeof(termType));
        }
        /*
         * Define one HOpotential
         */
        int SetOneHOP(int n, // number of nodes participating in this potential
            int* ind, // indices of participating nodes - needs to be allocated outside
            termType* weights,  // w_i for each node in the potential - needs to be allocated outside
            termType* gammas,  // gamma_l for all labels and gamma_max - do not allocate
            termType Q) // truncation term
        {
            // find a vacant slot to insert this HOpotential
            int hoi(0), ii(0);
            for ( ; hoi < nhigher && higherElements[hoi] > 0 ; hoi++);
            if ( hoi == nhigher ){
			    mexErrMsgIdAndTxt("robustpn:inputs","failed to load hop #xxxx"); 
                return -1; // no vacant slot for this HOpotential
            }
            higherElements[hoi] = n;
            higherTruncation[hoi] = Q;
            higherP[hoi] = 0;

            // do not allocate 
            higherWeights[hoi] = weights;
            higherIndex[hoi] = ind;
            
            for (ii = 0; ii<n ; ii++) {
                higherP[hoi]+=weights[ii];
				//printf("weights[%d] %f \n" , ii, weights[ii]);
            }
			//printf("Prepare to load hop higherP[%d] %f \n" , hoi, higherP[hoi]);
            if (2*Q >= higherP[hoi]) {
                // 2*Q must be smaller than P (see sec. 4.2 in tech-report)
				//mexErrMsgIdAndTxt("robustpn:inputs","failed to load hop #yyyy"); 
				//mexErrMsgIdAndTxt("robustpn:inputs","failed to load hop Q#%f", Q);
               return -1;
			//	mexErrMsgIdAndTxt("robustpn:inputs","failed to load hop higherP[hoi]# %f", higherP[hoi]);
            }
            memcpy(higherCost + (nlabel+1)*hoi, gammas, (nlabel+1)*sizeof(termType));

            return 1;            
        }
        /*
         * De-alocate memory
         */
		~Energy()
		{
			int i;
			if(higherIndex != NULL) for(i = 0; i < nhigher; i++) if(higherIndex[i] != NULL) delete[] higherIndex[i];
            if(higherWeights != NULL) for(i = 0; i < nhigher; i++) if(higherWeights[i] != NULL) delete[] higherWeights[i]; // BAGON
	
			if(pairCost != NULL) delete[] pairCost;
			if(unaryCost != NULL) delete[] unaryCost;
			if(pairIndex != NULL) delete[] pairIndex;

			if(higherTruncation != NULL) delete[] higherTruncation;
			//if(higherCost != NULL) delete[] higherCost;
			if(higherIndex != NULL) delete[] higherIndex;
			//if(higherElements != NULL) delete[] higherElements;
            if(higherWeights != NULL) delete[] higherWeights; // BAGON
            if(higherP != NULL) delete[] higherP; // BAGON
			
            
		}

        /*
         * Alocate memory for HOpotentails, pre-potential information (indices and w_i)
         *
		void AllocateHigherIndexes()
		{
			int i;
			for(i = 0;i < nhigher; i++) {                
                higherIndex[i] = new int[higherElements[i]];
                higherWeights[i] = new termType[higherElements[i]]; // BAGON
            }
		}
         */
};

#endif
