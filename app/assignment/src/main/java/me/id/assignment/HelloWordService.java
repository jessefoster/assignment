package me.id.assignment;

import me.id.assignment.dto.HelloWorld;

import javax.enterprise.context.ApplicationScoped;
import javax.inject.Inject;
import javax.persistence.EntityManager;
import javax.transaction.Transactional;
import java.util.Optional;

@ApplicationScoped
public class HelloWordService {

	@Inject
	EntityManager em;

	public Optional<HelloWorld> get(long id) {
		HelloWorld world = em.find(HelloWorld.class, id);
		return Optional.ofNullable(world);
	}

	@Transactional
	public Optional<HelloWorld> save(HelloWorld newHello) {
		em.persist( newHello );
		// Maybe will need to refetch
		return Optional.of( newHello );
	}
}
