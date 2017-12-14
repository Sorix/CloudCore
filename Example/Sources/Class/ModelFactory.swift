//
//  ModelFactory.swift
//  CloudCoreExample
//
//  Created by Vasily Ulianov on 13/12/2017.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation
import Fakery
import CoreData

class ModelFactory {
	
	private static let faker: Faker = {
		let locale = Locale.preferredLanguages.first ?? "en"
		return Faker(locale: locale)
	}()
	
	@discardableResult
	static func insertOrganizationWithEmployees(context: NSManagedObjectContext) -> Organization {
		let org = self.insertOrganization(context: context)
		org.sort = Int32(faker.number.randomInt(min: 1, max: 1000))
		
		for _ in 0...faker.number.randomInt(min: 0, max: 3) {
			let user = self.insertEmployee(context: context)
			user.organization = org
		}
		
		return org
	}
	
	// MARK: - Private methods
	
	private static func insertOrganization(context: NSManagedObjectContext) -> Organization {
		let org = Organization(context: context)
		org.name = faker.company.name()
		org.bs = faker.company.bs()
		org.founded = Date(timeIntervalSince1970: faker.number.randomDouble(min: 1292250324, max: 1513175137))

		return org
	}
	
	static func insertEmployee(context: NSManagedObjectContext) -> Employee {
		let user = Employee(context: context)
		user.department = faker.commerce.department()
		user.name = faker.name.name()
		user.workingSince = Date(timeIntervalSince1970: faker.number.randomDouble(min: 661109847, max: 1513186653))
		user.photoData = randomAvatar()
		
		return user
	}
	
	private static func randomAvatar() -> Data? {
		let randomNumber = String(faker.number.randomInt(min: 1, max: 9))
		let image = UIImage(named: "avatar_" + randomNumber)!
		return UIImagePNGRepresentation(image)
	}
	
	static func newCompanyName() -> String {
		return faker.company.name()
	}
	
}
