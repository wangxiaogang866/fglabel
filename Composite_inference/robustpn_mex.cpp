/*
 * Robust Higher-Order Potentials energy minimization:
 *
 * Usage:
 *  [L E] = robustpn_mex(sparseG, Dc, hop, init_labels)
 *
 * Inputs:
 *  sparseG - sparse adjecency matrix defining graph structure and pair-wise potentials
 *      sparseG(i,j) !=0 means i,j share a pair-wise potntial with value sparseG(i,j)
 *      sparseG is of size (#nodes)x(#nodes). The matrix must be symmetric (undirected graph)
 *  Dc - unary potential, i.e., data term of size (#labels)x(#nodes)
 *  hop - higher order potential array of structs with (#higher) entries, each entry:
 *      .ind - indices of nodes belonging to this hop
 *      .w - weights w_i for each participating node
 *      .gamma - #labels + 1 entries for gamma_1..gamma_max
 *      .Q - truncation value for this potential (assumes one Q for all labels)
 *  init_labels - (optional) initial guess of labeling (range 1..(#labels))
 *
 * Outputs:
 *  L - optimal labels
 *  E - obtained minimal energy [Unary Pairs HO Tot]
 *
 *
 *  This wrapper for Matlab was written by Shai Bagon (shai.bagon@weizmann.ac.il).
 *  Department of Computer Science and Applied Mathmatics
 *  Wiezmann Institute of Science
 *  http://www.wisdom.weizmann.ac.il/~bagon
 *   
 *	The core cpp application was written by Pushmeet Kohli, Lubor Ladicky and Philip H.S.Torr
 *  It is described in
 *
 *  P. Kohli, L. Ladicky, and P. Torr. Graph cuts for minimizing robust higher order potentials.
 *  Technical report, Oxford Brookes University, UK., 2008.
 *  
 *  P. Kohli, L. Ladicky, and P. Torr. Robust higher order potentials for enforcing label
 *  consistency. In CVPR, 2008.
 * 
 *  Yuri Boykov and Vladimir Kolmogorov. An Experimental Comparison of Min-Cut/Max-Flow Algorithms
 *  for Energy Minimization in Vision. In IEEE Transactions on Pattern Analysis and Machine
 *  Intelligence (PAMI), September 2004
 *  
 *  Matlab Wrapper for Robust P^N Potentials.
 *  Shai Bagon.
 *  in www.wisdom.weizmann.ac.il/~bagon, January 2009.
 * 
 *   This software can be used only for research purposes, you should  cite ALL of
 *   the aforementioned papers in any resulting publication.
 *   If you wish to use this software (or the algorithms described in the
 *   aforementioned paper)
 *   for commercial purposes, you should be aware that there is a US patent:
 *
 *       R. Zabih, Y. Boykov, O. Veksler,
 *       "System and method for fast approximate energy minimization via
 *       graph cuts",
 *       United Stated Patent 6,744,923, June 1, 2004
 *
 *
 *   The Software is provided "as is", without warranty of any kind.
 *
 *
 */

#include <mex.h>
#include "expand.h"   // minimize energy using alpha-expantion steps


// declarations
template<typename termType>
void robustpn(int nout, mxArray* pout[], int nin, const mxArray*pin[]);
template<class T>
void GetArr(const mxArray* x, T* arr, T bias = 0);

// consts
const int HOP_N_OF_FIELDS(4); // expecting 4 fields for the HOpotentials struct
const char* HOP_FIELDS[HOP_N_OF_FIELDS] = {"ind", "w", "gamma", "Q"};
const int MAX_ITER(50); // maximum 50 iterations


void
mexFunction(
    int nout,
    mxArray* pout[],
    int nin,
    const mxArray* pin[])
{
    if ( nout == 0 )
        return;
    if ( nin != 3 && nin != 4 )
        mexErrMsgIdAndTxt("robustpn:inputs","Must have 3 or 4 inputs");
    
    if (mxIsComplex(pin[1]))
        mexErrMsgIdAndTxt("robustpn:inputs","Dc must be a real-valued matrix");
    // check pin[1] is double/float - decide termType accordingly
    switch ( mxGetClassID(pin[1]) ) {
        case mxSINGLE_CLASS:
            // mexPrintf("Constructing single precision energy\n");
            return robustpn<float>(nout, pout, nin, pin);
        case mxDOUBLE_CLASS:
            // mexPrintf("Constructing double precision energy\n");            
            return robustpn<double>(nout, pout, nin, pin);
            default:
                mexErrMsgIdAndTxt("robustpn:inputs","Dc must be a non-integer matrix");
    }
    return;
}


// actual function according to desired termType class
template<typename termType>
void robustpn(int nout, mxArray* pout[], int nin, const mxArray* pin[])
{

    /*
     *********************************************************
     * Check inputs and construct the energy
     **********************************************************
     */
    
    int nLabel, nVar, nPair, nHigher, ii;
    int hop_fields_indices[HOP_N_OF_FIELDS]; // indices to fields in hop struct
    
    // check pin[0] is sparse
    if ( ! mxIsSparse(pin[0]) || ! mxIsDouble(pin[0]) || mxIsComplex(pin[0]))
        mexErrMsgIdAndTxt("robustpn:inputs","sparseG must be a sparse double matrix");
    // check pin[0] is square
    const mwSize *spd = mxGetDimensions(pin[0]);
    if (spd[0] != spd[1])
        mexErrMsgIdAndTxt("robustpn:inputs","sparseG must be a square matrix");
    nVar = spd[0];
    
    nPair = 0;
    // read the sparse matrix
    double* Pr = mxGetPr(pin[0]);
    mwIndex  *ir = mxGetIr(pin[0]);
    mwIndex *jc = mxGetJc(pin[0]);
    mwIndex col, starting_row_index, stopping_row_index, current_row_index, tot(0);
    
    mwSize max_npair = mxGetNzmax(pin[0]);
    int * pairs = new int[2 * max_npair]; // will be de-alocate on ~Energy
    termType* sc = new termType[max_npair]; // will be de-alocate on ~Energy

    // mexPrintf("Preparing to read sG\n");
    
    // traverse the sparseG matrix - pick only connections from the upper tri of the matrix
    // (since its symmetric and we don't want to count each potential twice).
    for (col=0; col<nVar; col++)  {
        starting_row_index = jc[col];
        stopping_row_index = jc[col+1];
        if (starting_row_index == stopping_row_index)
            continue;
        else {
            for (current_row_index = starting_row_index;
              current_row_index < stopping_row_index  ; 
              current_row_index++)  {
                if ( ir[current_row_index] >= col ) { // ignore lower tri of matrix
                    pairs[nPair*2] = ir[current_row_index]; // from
                    pairs[nPair*2 + 1] = col; // to
                    sc[nPair] = (termType)Pr[tot]; // potential weight
                    nPair++;
                }
                tot++;
            }
        }
    }
       
    // mexPrintf("Done reading sG got %d pairs\n", nPair);
    
    // check pin[1] has enough columns (=#nodes)
    const mwSize *sdc = mxGetDimensions(pin[1]);
    if (sdc[1] != spd[0])
        mexErrMsgIdAndTxt("robustpn:inputs","Dc must have %d columns to match graph structure", spd[0]);
    nLabel = sdc[0];
    
    
    // check pin[2] is struct array with proper feilds
    if ( mxGetClassID(pin[2]) != mxSTRUCT_CLASS )
        mexErrMsgIdAndTxt("robustpn:inputs","hop must be a struct array");
    nHigher = mxGetNumberOfElements(pin[2]);
    // expecting HOP_N_OF_FIELDS fieds
    if ( mxGetNumberOfFields(pin[2]) != HOP_N_OF_FIELDS )
        mexErrMsgIdAndTxt("robustpn:inputs","hop must have %d fields", HOP_N_OF_FIELDS);
    // chack that we have the right fields
    for ( ii = 0; ii < HOP_N_OF_FIELDS ; ii++ ) {
        hop_fields_indices[ii] = mxGetFieldNumber(pin[2], HOP_FIELDS[ii]);
        if ( hop_fields_indices[ii] < 0 )
            mexErrMsgIdAndTxt("robustpn:inputs","hop is missing %s field", HOP_FIELDS[ii]);
    }
    
    Energy<termType> *energy = new Energy<termType>(nLabel, nVar, nPair, nHigher);

    energy->SetUnaryCost( (termType*)mxGetData(pin[1]) );
    energy->SetPairCost(pairs, sc);
    delete[] pairs; // were copied into energy
    delete[] sc;
    
    // Add the HO potentials
    mxArray *xind, *xw, *xgamma, *xQ;
    int * ind, n;
    termType* w;
    termType* gamma;
    termType Q;
    for ( ii = 0 ; ii < nHigher; ii++ ) {
        xind = mxGetFieldByNumber(pin[2], ii, hop_fields_indices[0]);
        n = mxGetNumberOfElements(xind);
        ind = new int[n]; // allocation for energy
        GetArr(xind, ind, -1); // bias = -1 convert from 1-ind of matlab to 0-ind of C
        
        xw = mxGetFieldByNumber(pin[2], ii, hop_fields_indices[1]);
		//printf("weights[%d] %f \n" , ii, xw);
        if ( mxGetNumberOfElements(xw) != n ) {
            delete energy;
            delete[] ind;
            mexErrMsgIdAndTxt("robustpn:inputs","hop %d: number of indices is different than number of weights", ii);
        }
        w = new termType[n]; // allocation for energy
        GetArr(xw, w);
        
        xgamma = mxGetFieldByNumber(pin[2], ii, hop_fields_indices[2]);
        if ( mxGetNumberOfElements(xgamma) != nLabel+1 ) {
            delete energy;
            delete[] ind;
            delete[] w;
            mexErrMsgIdAndTxt("robustpn:inputs","hop %d: must have exactly %d gamma values", ii, nLabel+1);
        }
        gamma = new termType[nLabel+1];
        GetArr(xgamma, gamma);
        
        xQ = mxGetFieldByNumber(pin[2], ii, hop_fields_indices[3]);
        Q = (termType)mxGetScalar(xQ);
        
        if ( energy->SetOneHOP(n, ind, w, gamma, Q) < 0 ) {
            delete energy;
            delete[] gamma;
            mexErrMsgIdAndTxt("robustpn:inputs","failed to load hop #%d", ii);
        }
        delete[] gamma; // this array is being allocated inside energy
        // mexPrintf("Done reading hop(%d) / %d\n", ii, nHigher);
    }
    
    // mexPrintf("Done reading hops\n");
    /*
     *********************************************************
     * Minimize energy
     **********************************************************
     */
    //initialize alpha expansion - max MAX_ITER iterations
	AExpand<termType> *expand = new AExpand<termType>(energy, MAX_ITER);

    // must have at least one output for the labels
    pout[0] = mxCreateNumericMatrix(1, nVar, mxINT32_CLASS, mxREAL);
    int *solution = (int*)mxGetData(pout[0]);

    // Do we have an initial guess of labeling ?
    if ( nin == 4 ) {
        if ( mxGetNumberOfElements(pin[3]) != nVar )
            mexErrMsgIdAndTxt("robustpn:inputs","Initial guess of labeling must have exactly %d elements", nVar);
        GetArr(pin[3], solution, -1); // convert Matlab's 1-ind labeling to C's 0-ind labeling
    } else {
        // default initial labeling
        memset(solution, 0, nVar*sizeof(int));
    }
    termType ee[3];
    termType E(0);
    E = expand->minimize(solution, ee);

    if (nout>1) {
        pout[1] = mxCreateNumericMatrix(1, 4, mxGetClassID(pin[1]), mxREAL);
        termType *pE = (termType*)mxGetData(pout[1]);
        pE[0] = ee[0]; // unary energy
        pE[1] = ee[1]; // pair-wise energy
        pE[2] = ee[2]; // higher order energy
        pE[3] = E;
    }
    // de-allocate
    delete expand;
    delete energy;
}


template<class T>
void GetArr(const mxArray* x, T* arr, T bias)
{
    int ii, n = mxGetNumberOfElements(x);
    void *p = mxGetData(x);
    char* cp;
    unsigned char* ucp;
    short* sp;
    unsigned short* usp;
    int* ip;
    unsigned int* uip;
    int64_T *i64p;
    uint64_T *ui64p;
    double* dp;
    float* fp;
    
    switch (mxGetClassID(x)) {
        case mxCHAR_CLASS:
        case mxINT8_CLASS:    
            cp = (char*)p;
            for ( ii = 0 ; ii < n ; ii++)
                arr[ii] = cp[ii] + bias;
            return;
        case mxDOUBLE_CLASS:
            dp = (double*)p;
            for ( ii = 0 ; ii < n ; ii++)
                arr[ii] = dp[ii]+ bias;
            return;
        case mxSINGLE_CLASS:
            fp = (float*)p;
            for ( ii = 0 ; ii < n ; ii++)
                arr[ii] = fp[ii]+ bias;
            return;
        case mxUINT8_CLASS:
            ucp = (unsigned char*)p;
            for ( ii = 0 ; ii < n ; ii++)
                arr[ii] = ucp[ii]+ bias;
            return;
        case mxINT16_CLASS:
            sp = (short*)p;
            for ( ii = 0 ; ii < n ; ii++)
                arr[ii] = sp[ii]+ bias;
            return;
        case mxUINT16_CLASS:
            usp = (unsigned short*)p;
            for ( ii = 0 ; ii < n ; ii++)
                arr[ii] = usp[ii]+ bias;
            return;
        case mxINT32_CLASS:
            ip = (int*)p;
            for ( ii = 0 ; ii < n ; ii++)
                arr[ii] = ip[ii]+ bias;
            return;
        case mxUINT32_CLASS:
            uip = (unsigned int*)p;
            for ( ii = 0 ; ii < n ; ii++)
                arr[ii] = uip[ii]+ bias;
            return;
        case mxINT64_CLASS:
            i64p = (int64_T*)p;
            for ( ii = 0 ; ii < n ; ii++)
                arr[ii] = i64p[ii]+ bias;
            return;
        case mxUINT64_CLASS:
            ui64p = (uint64_T*)p;
            for ( ii = 0 ; ii < n ; ii++)
                arr[ii] = ui64p[ii]+ bias;
            return;
        default:
            mexErrMsgIdAndTxt("robustpn:GetArr","unsupported data type");
    }
}
