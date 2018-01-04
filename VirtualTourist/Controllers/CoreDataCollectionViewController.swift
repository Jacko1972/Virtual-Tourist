//
//  CoreDataCollectionViewController.swift
//  VirtualTourist
//
//  Created by Andrew Jackson on 28/12/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//

import UIKit
import CoreData

class CoreDataCollectionViewController: UICollectionViewController {

    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>?
    
    init(fetchedResultsController fc: NSFetchedResultsController<NSFetchRequestResult>, layout: UICollectionViewFlowLayout) {
        fetchedResultsController = fc
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10)
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

// MARK: UICollectionViewDataSource

extension CoreDataCollectionViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 0
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        fatalError("This method MUST be implemented by a subclass of CoreDataCollectionViewController")
    }
}
    // MARK: UICollectionViewDelegate

extension CoreDataCollectionViewController {

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
}
