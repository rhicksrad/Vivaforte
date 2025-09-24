using System;
using System.Collections.Generic;

namespace LifeForce.Core;

/// <summary>
/// Simple component registry that stores component instances by entity identifier.
/// </summary>
public sealed class ComponentStore
{
    private int _nextEntityId = 1;
    private readonly HashSet<int> _entities = new();
    private readonly Dictionary<Type, object> _components = new();

    /// <summary>
    /// Creates a new entity and returns its handle.
    /// </summary>
    public Entity CreateEntity()
    {
        var entity = new Entity(_nextEntityId++);
        _entities.Add(entity.Id);
        return entity;
    }

    /// <summary>
    /// Removes the entity and all of its components.
    /// </summary>
    public void DestroyEntity(Entity entity)
    {
        if (!_entities.Remove(entity.Id))
        {
            return;
        }

        foreach (var store in _components.Values)
        {
            var dictionary = (Dictionary<int, object>)store;
            dictionary.Remove(entity.Id);
        }
    }

    /// <summary>
    /// Removes all entities and components, resetting the store to its initial state.
    /// </summary>
    public void Clear()
    {
        _entities.Clear();
        foreach (var store in _components.Values)
        {
            var dictionary = (Dictionary<int, object>)store;
            dictionary.Clear();
        }

        _nextEntityId = 1;
    }

    /// <summary>
    /// Adds or replaces the component on the given entity.
    /// </summary>
    public void Add<T>(Entity entity, T component) where T : class
    {
        var store = GetStore<T>();
        store[entity.Id] = component;
    }

    /// <summary>
    /// Removes the component of the given type from the entity.
    /// </summary>
    public void Remove<T>(Entity entity) where T : class
    {
        var store = GetStore<T>();
        store.Remove(entity.Id);
    }

    /// <summary>
    /// Attempts to fetch the component for the entity.
    /// </summary>
    public bool TryGet<T>(Entity entity, out T? component) where T : class
    {
        var store = GetStore<T>();
        if (store.TryGetValue(entity.Id, out var boxed))
        {
            component = (T)boxed;
            return true;
        }

        component = null;
        return false;
    }

    /// <summary>
    /// Gets the component for the entity or throws when missing.
    /// </summary>
    public T Get<T>(Entity entity) where T : class
    {
        var store = GetStore<T>();
        return (T)store[entity.Id];
    }

    /// <summary>
    /// Returns whether the entity has the component type.
    /// </summary>
    public bool Has<T>(Entity entity) where T : class
    {
        var store = GetStore<T>();
        return store.ContainsKey(entity.Id);
    }

    /// <summary>
    /// Enumerates all active entities.
    /// </summary>
    public IEnumerable<Entity> Entities
    {
        get
        {
            foreach (var id in _entities)
            {
                yield return new Entity(id);
            }
        }
    }

    /// <summary>
    /// Enumerates all entities containing the requested components.
    /// </summary>
    public IEnumerable<Entity> With<T1, T2>()
        where T1 : class
        where T2 : class
    {
        var store1 = GetStore<T1>();
        var store2 = GetStore<T2>();

        foreach (var id in _entities)
        {
            if (store1.ContainsKey(id) && store2.ContainsKey(id))
            {
                yield return new Entity(id);
            }
        }
    }

    /// <summary>
    /// Enumerates all entities containing the requested components.
    /// </summary>
    public IEnumerable<Entity> With<T1, T2, T3>()
        where T1 : class
        where T2 : class
        where T3 : class
    {
        var store1 = GetStore<T1>();
        var store2 = GetStore<T2>();
        var store3 = GetStore<T3>();

        foreach (var id in _entities)
        {
            if (store1.ContainsKey(id) && store2.ContainsKey(id) && store3.ContainsKey(id))
            {
                yield return new Entity(id);
            }
        }
    }

    private Dictionary<int, object> GetStore<T>() where T : class
    {
        var type = typeof(T);
        if (!_components.TryGetValue(type, out var store))
        {
            store = new Dictionary<int, object>();
            _components[type] = store;
        }

        return (Dictionary<int, object>)store;
    }

}
